class McpTools::GetCommitmentSummary < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    Overall commitment status summary — how many commitments are not started, in progress,
    completed, or broken, broken down by policy area. This aggregates COMMITMENTS (not
    promises). If no commitments exist yet, totals will be zero even if promises are loaded.
    The government_id for the current Government of Canada is 1.
  DESC

  input_schema(
    properties: {
      government_id: { type: "integer", description: "Government ID (1 = current Government of Canada)" },
      source_type: { type: "string", description: "Filter by source type (e.g. 'platform_document', 'mandate_letter')" }
    },
    required: [ "government_id" ]
  )

  path_template "/api/dashboard/:government_id/at_a_glance"
end
