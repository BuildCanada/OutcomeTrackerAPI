class McpTools::ListBills < MCP::Tool
  include McpRackTool

  description <<~DESC.strip
    List Canadian parliamentary bills (45th Parliament). Returns bill_number_formatted
    (e.g. 'C-2', 'S-201'), short_title, long_title, latest_activity, and all stage
    dates tracking progress through Parliament: House 1st/2nd/3rd reading, Senate
    1st/2nd/3rd reading, and Royal Assent.
  DESC

  path_template "/bills"
end
