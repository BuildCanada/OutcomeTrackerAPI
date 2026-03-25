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
from agent.tools.db_read import get_entry, list_unprocessed_entries
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


# ── Agent-local tools (not served by the remote MCP server) ────────────────

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


# ── MCP Servers ────────────────────────────────────────────────────────────

# Agent-local tools that need direct DB access or are side-effecting.
# Read-only tracker tools are served by the remote MCP server (POST /mcp).
LOCAL_TOOLS = [
    get_entry_tool,
    list_unprocessed_entries_tool,
    fetch_government_page_tool,
]

agent_server = create_sdk_mcp_server(
    name="agent",
    version="1.0.0",
    tools=LOCAL_TOOLS,
)


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

    # Remote MCP server for read-only tracker tools (commitments, departments,
    # bills, promises, ministers, feed items, dashboard, burndown).
    # Agent-local MCP server for entry tools and fetch_government_page.
    tracker_url = os.environ.get("MCP_SERVER_URL", f"{rails_url}/mcp")

    remote_tools = [
        "mcp__tracker__list_policy_areas",
        "mcp__tracker__list_commitments", "mcp__tracker__get_commitment",
        "mcp__tracker__list_departments", "mcp__tracker__get_department",
        "mcp__tracker__list_promises", "mcp__tracker__get_promise",
        "mcp__tracker__list_bills", "mcp__tracker__get_bill",
        "mcp__tracker__list_ministers", "mcp__tracker__list_activity",
        "mcp__tracker__get_commitment_summary", "mcp__tracker__get_commitment_progress",
    ]
    local_tools = [f"mcp__agent__{t.name}" for t in LOCAL_TOOLS]
    allowed_tools = remote_tools + local_tools + ["Bash", "WebSearch"]

    return ClaudeAgentOptions(
        model=model,
        system_prompt=SYSTEM_PROMPT + api_context,
        mcp_servers={
            "tracker": {"type": "url", "url": tracker_url},
            "agent": agent_server,
        },
        allowed_tools=allowed_tools,
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
