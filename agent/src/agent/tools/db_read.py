"""Database read tools — direct read-only Postgres queries."""

import json

from agent.db import query, query_one


def get_commitment(commitment_id: int) -> dict:
    """Fetch a commitment with its criteria, matches, events, linked bills, and sources."""
    commitment = query_one(
        """
        SELECT c.*, pa.name AS policy_area_name, pa.slug AS policy_area_slug,
               g.name AS government_name
        FROM commitments c
        LEFT JOIN policy_areas pa ON pa.id = c.policy_area_id
        LEFT JOIN governments g ON g.id = c.government_id
        WHERE c.id = %s
        """,
        (commitment_id,),
    )
    if not commitment:
        return {"error": f"Commitment {commitment_id} not found"}

    criteria = query(
        """
        SELECT id, category, description, verification_method, status,
               evidence_notes, assessed_at, position
        FROM criteria
        WHERE commitment_id = %s
        ORDER BY category, position
        """,
        (commitment_id,),
    )

    matches = query(
        """
        SELECT cm.id, cm.matchable_type, cm.matchable_id, cm.relevance_score,
               cm.relevance_reasoning, cm.matched_at, cm.assessed,
               CASE
                 WHEN cm.matchable_type = 'Bill' THEN b.bill_number_formatted
                 WHEN cm.matchable_type = 'Entry' THEN e.title
                 ELSE NULL
               END AS matchable_title,
               CASE
                 WHEN cm.matchable_type = 'Bill' THEN b.short_title
                 WHEN cm.matchable_type = 'Entry' THEN e.url
                 ELSE NULL
               END AS matchable_detail
        FROM commitment_matches cm
        LEFT JOIN bills b ON cm.matchable_type = 'Bill' AND b.id = cm.matchable_id
        LEFT JOIN entries e ON cm.matchable_type = 'Entry' AND e.id = cm.matchable_id
        WHERE cm.commitment_id = %s
        ORDER BY cm.relevance_score DESC
        """,
        (commitment_id,),
    )

    events = query(
        """
        SELECT id, event_type, action_type, title, description, occurred_at, metadata
        FROM commitment_events
        WHERE commitment_id = %s
        ORDER BY occurred_at DESC
        LIMIT 50
        """,
        (commitment_id,),
    )

    sources = query(
        """
        SELECT cs.id, cs.section, cs.reference, cs.excerpt, cs.relevance_note,
               s.title AS source_title, s.source_type, s.url AS source_url, s.date AS source_date
        FROM commitment_sources cs
        JOIN sources s ON s.id = cs.source_id
        WHERE cs.commitment_id = %s
        """,
        (commitment_id,),
    )

    departments = query(
        """
        SELECT d.id, d.slug, d.display_name, d.official_name, cd.is_lead
        FROM commitment_departments cd
        JOIN departments d ON d.id = cd.department_id
        WHERE cd.commitment_id = %s
        ORDER BY cd.is_lead DESC
        """,
        (commitment_id,),
    )

    status_changes = query(
        """
        SELECT previous_status, new_status, changed_at, reason
        FROM commitment_status_changes
        WHERE commitment_id = %s
        ORDER BY changed_at DESC
        LIMIT 10
        """,
        (commitment_id,),
    )

    commitment["criteria"] = criteria
    commitment["matches"] = matches
    commitment["events"] = events
    commitment["sources"] = sources
    commitment["departments"] = departments
    commitment["status_changes"] = status_changes

    return _serialize(commitment)


def list_commitments(
    status: str | None = None,
    policy_area: str | None = None,
    commitment_type: str | None = None,
    stale_days: int | None = None,
    government_id: int | None = None,
    limit: int = 50,
    offset: int = 0,
) -> list[dict]:
    """List commitments with optional filters."""
    conditions = []
    params = []

    if status:
        # Map status name to integer
        status_map = {"not_started": 0, "in_progress": 1, "completed": 2, "broken": 4}
        if status in status_map:
            conditions.append("c.status = %s")
            params.append(status_map[status])

    if policy_area:
        conditions.append("pa.slug = %s")
        params.append(policy_area)

    if commitment_type:
        type_map = {
            "legislative": 0, "spending": 1, "procedural": 2,
            "institutional": 3, "diplomatic": 4, "aspirational": 5, "outcome": 6,
        }
        if commitment_type in type_map:
            conditions.append("c.commitment_type = %s")
            params.append(type_map[commitment_type])

    if stale_days:
        conditions.append(
            "(c.last_assessed_at IS NULL OR c.last_assessed_at < NOW() - INTERVAL '%s days')"
        )
        params.append(stale_days)

    if government_id:
        conditions.append("c.government_id = %s")
        params.append(government_id)

    where = "WHERE " + " AND ".join(conditions) if conditions else ""

    params.extend([limit, offset])

    results = query(
        f"""
        SELECT c.id, c.title, c.description, c.commitment_type, c.status,
               c.target_date, c.date_promised, c.last_assessed_at,
               pa.name AS policy_area_name, pa.slug AS policy_area_slug,
               (SELECT COUNT(*) FROM criteria cr WHERE cr.commitment_id = c.id) AS criteria_count,
               (SELECT COUNT(*) FROM commitment_matches cm WHERE cm.commitment_id = c.id) AS matches_count
        FROM commitments c
        LEFT JOIN policy_areas pa ON pa.id = c.policy_area_id
        {where}
        ORDER BY c.last_assessed_at ASC NULLS FIRST, c.id
        LIMIT %s OFFSET %s
        """,
        tuple(params),
    )
    return [_serialize(r) for r in results]


def get_bill(bill_id: int) -> dict:
    """Fetch a bill with stage dates and linked commitments."""
    bill = query_one(
        """
        SELECT id, bill_id, bill_number_formatted, parliament_number,
               short_title, long_title, latest_activity,
               passed_house_first_reading_at, passed_house_second_reading_at,
               passed_house_third_reading_at,
               passed_senate_first_reading_at, passed_senate_second_reading_at,
               passed_senate_third_reading_at,
               received_royal_assent_at, latest_activity_at
        FROM bills
        WHERE id = %s
        """,
        (bill_id,),
    )
    if not bill:
        return {"error": f"Bill {bill_id} not found"}

    linked_commitments = query(
        """
        SELECT cm.commitment_id, cm.relevance_score, cm.relevance_reasoning,
               c.title AS commitment_title, c.status AS commitment_status
        FROM commitment_matches cm
        JOIN commitments c ON c.id = cm.commitment_id
        WHERE cm.matchable_type = 'Bill' AND cm.matchable_id = %s
        ORDER BY cm.relevance_score DESC
        """,
        (bill_id,),
    )
    bill["linked_commitments"] = linked_commitments
    return _serialize(bill)


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


def get_commitment_sources(commitment_id: int) -> list[dict]:
    """Get the source documents (platform, SFT, budget) for a commitment."""
    results = query(
        """
        SELECT cs.section, cs.reference, cs.excerpt, cs.relevance_note,
               s.title, s.source_type, s.url, s.date
        FROM commitment_sources cs
        JOIN sources s ON s.id = cs.source_id
        WHERE cs.commitment_id = %s
        """,
        (commitment_id,),
    )
    return [_serialize(r) for r in results]


def get_bills_for_parliament(parliament_number: int = 45) -> list[dict]:
    """Get all government bills for a parliament session."""
    results = query(
        """
        SELECT id, bill_id, bill_number_formatted, short_title, long_title,
               latest_activity, latest_activity_at,
               passed_house_first_reading_at, passed_house_second_reading_at,
               passed_house_third_reading_at,
               passed_senate_first_reading_at, passed_senate_second_reading_at,
               passed_senate_third_reading_at,
               received_royal_assent_at
        FROM bills
        WHERE parliament_number = %s
          AND data->>'BillTypeEn' IN ('House Government Bill', 'Senate Government Bill')
        ORDER BY latest_activity_at DESC NULLS LAST
        """,
        (parliament_number,),
    )
    return [_serialize(r) for r in results]


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
