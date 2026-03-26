class McpTools::ListDepartments < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    List all ~32 federal government departments. Returns: id, display_name, slug,
    official_name, priority, and minister info (name, title, contact details,
    hill office) if a minister is assigned.
  DESC

  path_template "/departments"
end
