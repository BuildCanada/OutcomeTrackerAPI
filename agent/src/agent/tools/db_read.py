"""Database read tools for agent-internal queries not served by the remote MCP server."""

from agent.db import query, query_one


def _serialize(obj: dict) -> dict:
    """Serialize datetime and other non-JSON-serializable types."""
    from datetime import date, datetime
    from decimal import Decimal

    result = {}
    for key, value in obj.items():
        if isinstance(value, (datetime, date)):
            result[key] = value.isoformat()
        elif isinstance(value, Decimal):
            result[key] = float(value)
        elif isinstance(value, list):
            result[key] = [_serialize(v) if isinstance(v, dict) else v for v in value]
        elif isinstance(value, dict):
            result[key] = _serialize(value)
        else:
            result[key] = value
    return result


def get_entry(entry_id: int) -> dict:
    """Fetch an entry with its parsed content and feed info."""
    entry = query_one(
        """
        SELECT e.id, e.title, e.url, e.published_at, e.scraped_at,
               e.summary, e.parsed_markdown, e.activities_extracted_at,
               f.title AS feed_title, f.source_url AS feed_source_url
        FROM entries e
        JOIN feeds f ON f.id = e.feed_id
        WHERE e.id = %s
        """,
        (entry_id,),
    )
    if not entry:
        return {"error": f"Entry {entry_id} not found"}
    return _serialize(entry)


def list_unprocessed_entries(government_id: int | None = None, limit: int = 50) -> list[dict]:
    """Entries that have been scraped but not yet processed by the agent."""
    conditions = ["e.scraped_at IS NOT NULL", "e.skipped_at IS NULL"]
    params = []

    if government_id:
        conditions.append("e.government_id = %s")
        params.append(government_id)

    where = "WHERE " + " AND ".join(conditions)
    params.append(limit)

    results = query(
        f"""
        SELECT e.id, e.title, e.url, e.published_at, e.scraped_at,
               e.activities_extracted_at,
               f.title AS feed_title
        FROM entries e
        JOIN feeds f ON f.id = e.feed_id
        {where}
        ORDER BY e.published_at DESC
        LIMIT %s
        """,
        tuple(params),
    )
    return [_serialize(r) for r in results]
