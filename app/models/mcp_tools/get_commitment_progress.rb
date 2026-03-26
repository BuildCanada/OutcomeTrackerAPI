class McpTools::GetCommitmentProgress < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    Commitment progress over time — daily time-series of how many commitments have been
    scoped, started, completed, or broken throughout a government's mandate. Useful for
    trend analysis and charting. Returns { date, scope, started, completed, broken } per
    day, plus mandate_start/end dates. Tracks COMMITMENTS (not promises).
    The government_id for the current Government of Canada is 1.
  DESC

  input_schema(
    properties: {
      government_id: { type: "integer", description: "Government ID (1 = current Government of Canada)" },
      source_type: { type: "string", description: "Filter by source type" },
      policy_area_slug: { type: "string", description: "Filter by policy area slug" },
      department_slug: { type: "string", description: "Filter by lead department slug" }
    },
    required: [ "government_id" ]
  )

  path_template "/api/burndown/:government_id"
end
