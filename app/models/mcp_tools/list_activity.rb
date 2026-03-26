class McpTools::ListActivity < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    Chronological feed of government activity on tracked commitments. Best tool for
    "what's happening" or "what changed recently." Returns: event_type, title, summary,
    occurred_at, linked commitment, and policy_area. Paginated, most recent first.
    Note: only populated when the evaluation agent has assessed commitments and
    created events — will be empty if no commitments have been evaluated yet.
  DESC

  input_schema(
    properties: {
      commitment_id: { type: "integer", description: "Filter to one commitment's activity" },
      event_type: { type: "string", description: "Filter by event type" },
      policy_area_id: { type: "integer", description: "Filter by policy area ID" },
      since: { type: "string", description: "Activity after this date (ISO 8601, e.g. '2025-06-01')" },
      until: { type: "string", description: "Activity before this date (ISO 8601)" },
      page: { type: "integer", description: "Page number (default: 1)" },
      per_page: { type: "integer", description: "Results per page, max 100 (default: 50)" }
    }
  )

  path_template "/feed"
end
