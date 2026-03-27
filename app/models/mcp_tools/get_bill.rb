class McpTools::GetBill < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    Get full details for a parliamentary bill. Returns all fields including stage
    dates and the complete raw data from the Parliament of Canada API (sponsor,
    type, session info).
  DESC

  input_schema(
    properties: { id: { type: "integer", description: "The bill database ID" } },
    required: [ "id" ]
  )

  path_template "/bills/:id"
end
