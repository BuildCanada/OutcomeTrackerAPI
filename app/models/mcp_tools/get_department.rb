class McpTools::GetDepartment < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    Get department details including minister info (hill office, constituency offices)
    and the department's lead commitments. Accepts numeric ID or
    slug (e.g. 'finance-canada', 'national-defence').
  DESC

  input_schema(
    properties: { id_or_slug: { type: "string", description: "Department ID or slug" } },
    required: [ "id_or_slug" ]
  )

  path_template "/departments/:id_or_slug"
end
