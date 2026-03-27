class McpTools::GetCommitment < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    Get full details for a single commitment. Returns all nested data: sources
    (original government documents), criteria (completion/success/progress/failure
    with assessment history), departments, timeline events, status_history,
    and recent_feed items.
  DESC

  input_schema(
    properties: { id: { type: "integer", description: "The commitment ID" } },
    required: [ "id" ]
  )

  path_template "/commitments/:id"
end
