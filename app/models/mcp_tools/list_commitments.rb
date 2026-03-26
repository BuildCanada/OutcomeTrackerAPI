class McpTools::ListCommitments < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    Search and filter government commitments — the core accountability tracking unit.
    The Build Canada data model: Promises (raw political pledges) → Commitments
    (specific, measurable outcomes with status tracking) → Evidence (bills, events, sources).
    Each commitment has a status (not_started/in_progress/completed/broken), a type,
    a policy area, and a lead department. Returns paginated results with
    meta { total_count, page, per_page }.
    Use get_commitment_summary to discover valid policy area slugs.
  DESC

  input_schema(
    properties: {
      q: { type: "string", description: "Full-text search on title and description" },
      status: { type: "string", enum: %w[not_started in_progress completed broken], description: "Filter by commitment status" },
      policy_area: { type: "string", description: "Policy area slug (e.g. 'defence', 'healthcare', 'economy')" },
      commitment_type: { type: "string", enum: %w[legislative spending procedural institutional diplomatic aspirational outcome], description: "Filter by commitment type" },
      department: { type: "string", description: "Department slug (e.g. 'finance-canada')" },
      sort: { type: "string", enum: %w[title date_promised last_assessed_at status], description: "Sort field (default: created_at desc)" },
      direction: { type: "string", enum: %w[asc desc], description: "Sort direction (default: desc)" },
      page: { type: "integer", description: "Page number (default: 1)" },
      per_page: { type: "integer", description: "Results per page, max 1000 (default: 50)" }
    }
  )

  path_template "/commitments"
end
