"""Core agent evaluator — drives commitment evaluation using the Claude Agent SDK."""

import asyncio
import json
import os
import pathlib
import sys
import traceback
from datetime import date
from typing import Any

from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ResultMessage,
    ToolAnnotations,
    create_sdk_mcp_server,
    query,
    tool,
)

from agent.prompts import (
    EVALUATE_COMMITMENT_PROMPT,
    PROCESS_BILL_CHANGE_PROMPT,
    PROCESS_ENTRY_PROMPT,
    SYSTEM_PROMPT,
    WEEKLY_SCAN_PROMPT,
)
from agent.tools.db_read import (
    get_bill,
    get_bills_for_parliament,
    get_commitment,
    get_commitment_sources,
    get_entry,
    list_commitments,
    list_unprocessed_entries,
)
from agent.tools.web_search import fetch_government_page
from agent.tools.rails_write import register_source


def _tool_log(tool_name: str, msg: str) -> None:
    print(f"  [{tool_name}] {msg}", file=sys.stderr, flush=True)


def _tool_result(data: dict, tool_name: str) -> dict[str, Any]:
    text = json.dumps(data, default=str)
    _tool_log(tool_name, f"OK ({len(text)} chars)")
    return {"content": [{"type": "text", "text": text}]}


def _tool_error(e: Exception, tool_name: str, args: dict) -> dict[str, Any]:
    tb = traceback.format_exc()
    args_preview = json.dumps(args, default=str)[:300]
    tb_preview = tb[-500:]
    _tool_log(tool_name, f"ERROR: {type(e).__name__}: {e}")
    _tool_log(tool_name, f"  args: {args_preview}")
    _tool_log(tool_name, f"  traceback:\n{tb_preview}")
    error_detail = f"Error calling {tool_name}: {type(e).__name__}: {e}\nArgs: {args_preview}"
    return {
        "content": [{"type": "text", "text": error_detail}],
        "is_error": True,
    }


# ── Read-only DB tools (via MCP) ───────────────────────────────────────────

@tool(
    "get_commitment",
    "Fetch a commitment with its criteria, matches, events, linked bills, departments, and source documents.",
    {"commitment_id": int},
    annotations=ToolAnnotations(readOnlyHint=True),
)
async def get_commitment_tool(args: dict[str, Any]) -> dict[str, Any]:
    _tool_log("get_commitment", f"Loading commitment {args['commitment_id']}")
    try:
        return _tool_result(get_commitment(args["commitment_id"]), "get_commitment")
    except Exception as e:
        return _tool_error(e, "get_commitment", args)


@tool(
    "list_commitments",
    "List commitments with optional filters. Params: status, policy_area, commitment_type, stale_days, limit.",
    {
        "type": "object",
        "properties": {
            "status": {"type": "string", "enum": ["not_started", "in_progress", "completed", "broken"]},
            "policy_area": {"type": "string", "description": "Policy area slug"},
            "commitment_type": {"type": "string"},
            "stale_days": {"type": "integer"},
            "limit": {"type": "integer"},
        },
    },
    annotations=ToolAnnotations(readOnlyHint=True),
)
async def list_commitments_tool(args: dict[str, Any]) -> dict[str, Any]:
    _tool_log("list_commitments", f"filters: {args}")
    try:
        return _tool_result(list_commitments(**args), "list_commitments")
    except Exception as e:
        return _tool_error(e, "list_commitments", args)


@tool(
    "get_bill",
    "Fetch a bill with all stage dates (House/Senate readings, Royal Assent) and linked commitments.",
    {"bill_id": int},
    annotations=ToolAnnotations(readOnlyHint=True),
)
async def get_bill_tool(args: dict[str, Any]) -> dict[str, Any]:
    _tool_log("get_bill", f"Loading bill {args['bill_id']}")
    try:
        return _tool_result(get_bill(args["bill_id"]), "get_bill")
    except Exception as e:
        return _tool_error(e, "get_bill", args)


@tool(
    "get_entry",
    "Fetch a scraped entry (news article, gazette item) with parsed content.",
    {"entry_id": int},
    annotations=ToolAnnotations(readOnlyHint=True),
)
async def get_entry_tool(args: dict[str, Any]) -> dict[str, Any]:
    _tool_log("get_entry", f"Loading entry {args['entry_id']}")
    try:
        return _tool_result(get_entry(args["entry_id"]), "get_entry")
    except Exception as e:
        return _tool_error(e, "get_entry", args)


@tool(
    "list_unprocessed_entries",
    "List entries that have been scraped but not yet evaluated by the agent.",
    {"type": "object", "properties": {"limit": {"type": "integer"}}},
    annotations=ToolAnnotations(readOnlyHint=True),
)
async def list_unprocessed_entries_tool(args: dict[str, Any]) -> dict[str, Any]:
    _tool_log("list_unprocessed_entries", f"args: {args}")
    try:
        return _tool_result(list_unprocessed_entries(**args), "list_unprocessed_entries")
    except Exception as e:
        return _tool_error(e, "list_unprocessed_entries", args)


@tool(
    "get_commitment_sources",
    "Get the source documents (platform, Speech from the Throne, budget) for a commitment. Use this to determine where a commitment originated for the budget evidence rule.",
    {"commitment_id": int},
    annotations=ToolAnnotations(readOnlyHint=True),
)
async def get_commitment_sources_tool(args: dict[str, Any]) -> dict[str, Any]:
    _tool_log("get_commitment_sources", f"commitment {args['commitment_id']}")
    try:
        return _tool_result(get_commitment_sources(args["commitment_id"]), "get_commitment_sources")
    except Exception as e:
        return _tool_error(e, "get_commitment_sources", args)


@tool(
    "get_bills_for_parliament",
    "Get all government bills for a parliament session with their stage dates.",
    {"type": "object", "properties": {"parliament_number": {"type": "integer"}}},
    annotations=ToolAnnotations(readOnlyHint=True),
)
async def get_bills_for_parliament_tool(args: dict[str, Any]) -> dict[str, Any]:
    pn = args.get("parliament_number", 45)
    _tool_log("get_bills_for_parliament", f"parliament {pn}")
    try:
        return _tool_result(get_bills_for_parliament(pn), "get_bills_for_parliament")
    except Exception as e:
        return _tool_error(e, "get_bills_for_parliament", args)


@tool(
    "fetch_government_page",
    "Fetch and parse content from an official Canadian government webpage (*.canada.ca / *.gc.ca only). "
    "The page is automatically saved as a Source in the database. You MUST fetch pages before using their "
    "URLs in write operations (assess_criterion, update_commitment_status, create_commitment_event).",
    {
        "type": "object",
        "properties": {
            "url": {"type": "string", "description": "The government page URL to fetch"},
            "government_id": {"type": "integer", "description": "Government ID (usually 1)"},
        },
        "required": ["url", "government_id"],
    },
    annotations=ToolAnnotations(openWorldHint=True),
)
async def fetch_government_page_tool(args: dict[str, Any]) -> dict[str, Any]:
    url = args.get("url", "")
    gov_id = args.get("government_id", 1)
    _tool_log("fetch", f"GET {url[:100]}")
    try:
        result = fetch_government_page(url)
        if "error" in result:
            _tool_log("fetch", f"FAILED: {result['error']}")
            return {
                "content": [{"type": "text", "text": f"Fetch failed for {url}: {result['error']}"}],
                "is_error": True,
            }

        _tool_log("fetch", f"OK {len(result.get('content_markdown', ''))} chars — registering source...")

        source_result = register_source(
            government_id=gov_id,
            url=result.get("url", url),
            title=result.get("title", ""),
            date=result.get("published_date"),
        )
        if "error" in source_result:
            _tool_log("fetch", f"SOURCE REGISTRATION FAILED: {source_result['error']}")
            # Still return the content even if source registration failed
            result["source_id"] = None
            result["source_error"] = source_result["error"]
        else:
            source_id = source_result.get("id")
            existed = source_result.get("existed", False)
            _tool_log("fetch", f"source_id={source_id} {'(existed)' if existed else '(created)'}")
            result["source_id"] = source_id

        return {"content": [{"type": "text", "text": json.dumps(result, default=str)}]}
    except Exception as e:
        return _tool_error(e, "fetch_government_page", args)


# ── MCP Server (read tools + fetch only) ───────────────────────────────────

ALL_TOOLS = [
    get_commitment_tool,
    list_commitments_tool,
    get_bill_tool,
    get_entry_tool,
    list_unprocessed_entries_tool,
    get_commitment_sources_tool,
    get_bills_for_parliament_tool,
    fetch_government_page_tool,
]

tracker_server = create_sdk_mcp_server(
    name="tracker",
    version="1.0.0",
    tools=ALL_TOOLS,
)

ALLOWED_TOOLS = [f"mcp__tracker__{t.name}" for t in ALL_TOOLS] + ["Bash", "WebSearch"]


# ── Agent runner ────────────────────────────────────────────────────────────

def _build_options() -> ClaudeAgentOptions:
    rails_url = os.environ.get("RAILS_API_URL", "http://localhost:3000")
    rails_key = os.environ.get("RAILS_API_KEY", "")

    api_context = (
        f"\n\n## Rails API Connection\n"
        f"Base URL: `{rails_url}`\n"
        f"Auth header: `Authorization: Bearer {rails_key}`\n"
        f"Use `curl -s` via Bash for all write operations. "
        f"See CLAUDE.md for endpoint details and enum values.\n"
    )

    model = os.environ.get("AGENT_MODEL", "claude-sonnet-4-6")

    return ClaudeAgentOptions(
        model=model,
        system_prompt=SYSTEM_PROMPT + api_context,
        mcp_servers={"tracker": tracker_server},
        allowed_tools=ALLOWED_TOOLS,
        permission_mode="bypassPermissions",
        cwd=str(pathlib.Path(__file__).resolve().parent.parent.parent),  # agent/ dir where CLAUDE.md lives
        setting_sources=["project"],
    )


async def _run_agent(prompt: str, as_of_date: str | None = None) -> str:
    """Run the agent loop and return the final result text."""
    import time as _time

    current_date = as_of_date or date.today().isoformat()
    formatted_prompt = prompt.format(current_date=current_date)
    options = _build_options()

    start = _time.time()
    tool_count = 0
    result_text = ""

    def _log(msg: str) -> None:
        elapsed = _time.time() - start
        print(f"[{elapsed:6.1f}s] {msg}", flush=True)

    _log("Starting agent...")
    _log(f"Prompt: {formatted_prompt[:120]}...")

    async for message in query(prompt=formatted_prompt, options=options):
        elapsed = _time.time() - start
        msg_type = type(message).__name__

        if isinstance(message, AssistantMessage):
            for block in message.content:
                if hasattr(block, "text") and block.text:
                    preview = block.text[:200].replace("\n", " ")
                    _log(f"💬 {preview}{'...' if len(block.text) > 200 else ''}")
                elif hasattr(block, "name"):
                    tool_count += 1
                    tool_input = getattr(block, "input", {})
                    input_preview = json.dumps(tool_input, default=str)[:100]
                    _log(f"🔧 [{tool_count}] {block.name}({input_preview})")
        elif isinstance(message, ResultMessage):
            if message.subtype == "success":
                result_text = message.result or ""
                _log(f"✅ Done — {tool_count} tool calls, {elapsed:.1f}s total")
            else:
                result_text = f"Agent ended with: {message.subtype}"
                _log(f"⚠️  Ended: {message.subtype}")
        else:
            subtype = getattr(message, "subtype", "")
            if subtype == "init":
                session_id = getattr(message, "session_id", "?")
                _log(f"🚀 Session initialized: {session_id}")

    return result_text


def evaluate_commitment(commitment_id: int, as_of_date: str | None = None) -> str:
    prompt = EVALUATE_COMMITMENT_PROMPT.format(
        commitment_id=commitment_id, current_date="{current_date}",
    )
    return asyncio.run(_run_agent(prompt, as_of_date))


def process_entry(entry_id: int, as_of_date: str | None = None) -> str:
    prompt = PROCESS_ENTRY_PROMPT.format(
        entry_id=entry_id, current_date="{current_date}",
    )
    return asyncio.run(_run_agent(prompt, as_of_date))


def process_bill_change(bill_id: int, as_of_date: str | None = None) -> str:
    prompt = PROCESS_BILL_CHANGE_PROMPT.format(
        bill_id=bill_id, current_date="{current_date}",
    )
    return asyncio.run(_run_agent(prompt, as_of_date))


def weekly_scan_commitment(commitment_id: int, as_of_date: str | None = None) -> str:
    prompt = WEEKLY_SCAN_PROMPT.format(
        commitment_id=commitment_id, current_date="{current_date}",
    )
    return asyncio.run(_run_agent(prompt, as_of_date))
