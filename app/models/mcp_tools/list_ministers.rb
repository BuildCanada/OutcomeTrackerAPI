class McpTools::ListMinisters < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    List current cabinet ministers and officials. Returns: name, title, avatar_url,
    email, phone, website, constituency, province, and their department assignment.
  DESC

  path_template "/ministers"
end
