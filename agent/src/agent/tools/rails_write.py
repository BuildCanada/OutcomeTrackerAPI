"""Rails API write tools — HTTP calls to /api/agent/* for mutations."""

import os
import sys

import httpx


def _api_url() -> str:
    return os.environ.get("RAILS_API_URL", "http://localhost:3000")


def _api_key() -> str:
    return os.environ["RAILS_API_KEY"]


def _headers() -> dict:
    return {
        "Authorization": f"Bearer {_api_key()}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


def _post(path: str, data: dict) -> dict:
    url = f"{_api_url()}{path}"
    print(f"  [rails] POST {url}", file=sys.stderr, flush=True)
    try:
        resp = httpx.post(url, json=data, headers=_headers(), timeout=60.0)
        print(f"  [rails] → {resp.status_code}", file=sys.stderr, flush=True)
        if resp.status_code >= 400:
            err = f"API error {resp.status_code}: {resp.text[:300]}"
            print(f"  [rails] ERROR: {err}", file=sys.stderr, flush=True)
            return {"error": err}
        return resp.json()
    except Exception as e:
        print(f"  [rails] EXCEPTION: {e}", file=sys.stderr, flush=True)
        return {"error": str(e)}


def _patch(path: str, data: dict) -> dict:
    url = f"{_api_url()}{path}"
    print(f"  [rails] PATCH {url}", file=sys.stderr, flush=True)
    try:
        resp = httpx.patch(url, json=data, headers=_headers(), timeout=60.0)
        print(f"  [rails] → {resp.status_code}", file=sys.stderr, flush=True)
        if resp.status_code >= 400:
            err = f"API error {resp.status_code}: {resp.text[:300]}"
            print(f"  [rails] ERROR: {err}", file=sys.stderr, flush=True)
            return {"error": err}
        return resp.json()
    except Exception as e:
        print(f"  [rails] EXCEPTION: {e}", file=sys.stderr, flush=True)
        return {"error": str(e)}


def fetch_page(url: str, government_id: int) -> dict:
    """Fetch a government page through Rails — auto-creates Source record."""
    return _post(
        "/api/agent/pages/fetch",
        {
            "url": url,
            "government_id": government_id,
        },
    )


def assess_criterion(
    criterion_id: int,
    new_status: str,
    evidence_notes: str,
    source_url: str,
) -> dict:
    """Assess a criterion — requires source_url. Creates a CriterionAssessment audit record."""
    return _patch(
        f"/api/agent/criteria/{criterion_id}",
        {
            "new_status": new_status,
            "evidence_notes": evidence_notes,
            "source_url": source_url,
        },
    )


def update_commitment_status(
    commitment_id: int,
    new_status: str,
    reasoning: str,
    source_urls: list[str],
) -> dict:
    """Update commitment status — requires source_urls. Creates a CommitmentStatusChange audit record."""
    return _patch(
        f"/api/agent/commitments/{commitment_id}/status",
        {
            "new_status": new_status,
            "reasoning": reasoning,
            "source_urls": source_urls,
        },
    )


def link_bill_to_commitment(
    bill_id: int,
    commitment_id: int,
    relevance_score: float,
    relevance_reasoning: str,
) -> dict:
    """Link a bill to a commitment via CommitmentMatch."""
    return _post(
        "/api/agent/commitment_matches",
        {
            "commitment_id": commitment_id,
            "matchable_type": "Bill",
            "matchable_id": bill_id,
            "relevance_score": relevance_score,
            "relevance_reasoning": relevance_reasoning,
        },
    )


def create_commitment_event(
    commitment_id: int,
    event_type: str,
    title: str,
    description: str,
    occurred_at: str,
    source_url: str,
    action_type: str | None = None,
    metadata: dict | None = None,
) -> dict:
    """Create a CommitmentEvent — requires source_url. Auto-creates FeedItem via Rails callback."""
    return _post(
        "/api/agent/commitment_events",
        {
            "commitment_id": commitment_id,
            "event_type": event_type,
            "action_type": action_type,
            "title": title,
            "description": description,
            "occurred_at": occurred_at,
            "source_url": source_url,
            "metadata": metadata or {},
        },
    )


def register_source(
    government_id: int,
    url: str,
    title: str,
    date: str | None = None,
) -> dict:
    """Register a fetched page as a Source in Rails. Infers source_type from URL."""
    source_type = "other"
    if "gazette.gc.ca" in url:
        source_type = "gazette_notice"
    elif "budget" in url or "finance" in url:
        source_type = "budget"

    return _post(
        "/api/agent/sources",
        {
            "government_id": government_id,
            "url": url,
            "title": title or f"Government page: {url[:80]}",
            "source_type": source_type,
            "source_type_other": "government_webpage" if source_type == "other" else None,
            "date": date,
        },
    )


def add_source(
    government_id: int,
    url: str,
    title: str,
    source_type: str,
    date: str | None = None,
) -> dict:
    """Create a Source record if not already in the database."""
    return _post(
        "/api/agent/sources",
        {
            "government_id": government_id,
            "url": url,
            "title": title,
            "source_type": source_type,
            "date": date,
        },
    )


def record_evaluation_run(
    commitment_id: int,
    trigger_type: str,
    reasoning: str,
    previous_status: str | None = None,
    new_status: str | None = None,
    criteria_assessed: int = 0,
    evidence_found: int = 0,
    search_queries: list[str] | None = None,
    duration_seconds: float | None = None,
    agent_run_id: str | None = None,
) -> dict:
    """Record an audit trail for this evaluation run."""
    return _post(
        "/api/agent/evaluation_runs",
        {
            "commitment_id": commitment_id,
            "agent_run_id": agent_run_id,
            "trigger_type": trigger_type,
            "reasoning": reasoning,
            "previous_status": previous_status,
            "new_status": new_status,
            "criteria_assessed": criteria_assessed,
            "evidence_found": evidence_found,
            "search_queries": search_queries or [],
            "duration_seconds": duration_seconds,
        },
    )
