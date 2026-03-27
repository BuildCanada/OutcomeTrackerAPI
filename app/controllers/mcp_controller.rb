class McpController < ActionController::API
  TOOLS = [
    McpTools::ListCommitments,
    McpTools::GetCommitment,
    McpTools::ListBills,
    McpTools::GetBill,
    McpTools::ListDepartments,
    McpTools::GetDepartment,
    McpTools::ListMinisters,
    McpTools::ListActivity,
    McpTools::GetCommitmentSummary,
    McpTools::GetCommitmentProgress
  ].freeze

  def create
    server = MCP::Server.new(name: "build-canada-tracker", version: "1.0.0", tools: TOOLS)
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true)
    server.transport = transport

    resp_status, resp_headers, resp_body = transport.handle_request(request)
    resp_headers&.each { |key, value| response.headers[key] = value }
    render json: resp_body&.first, status: resp_status
  end
end
