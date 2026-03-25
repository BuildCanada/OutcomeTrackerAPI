require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  MCP_HEADERS = { "Accept" => "application/json, text/event-stream", "Content-Type" => "application/json" }

  def mcp_initialize
    post "/mcp", params: {
      jsonrpc: "2.0", id: 1, method: "initialize",
      params: { protocolVersion: "2025-03-26", capabilities: {}, clientInfo: { name: "test", version: "1.0" } }
    }.to_json, headers: MCP_HEADERS
  end

  def mcp_call(tool_name, arguments = {})
    post "/mcp", params: {
      jsonrpc: "2.0", id: 2, method: "tools/call",
      params: { name: tool_name, arguments: arguments }
    }.to_json, headers: MCP_HEADERS
  end

  # -- Protocol --

  test "initialize returns server capabilities" do
    mcp_initialize
    assert_response :success
  end

  test "tools/list returns registered tools" do
    mcp_initialize
    post "/mcp", params: { jsonrpc: "2.0", id: 2, method: "tools/list", params: {} }.to_json, headers: MCP_HEADERS
    assert_response :success
  end

  # -- Commitments --

  test "list_commitments with no filters" do
    mcp_initialize
    mcp_call("list_commitments")
    assert_response :success
  end

  test "list_commitments filtered by status" do
    mcp_initialize
    mcp_call("list_commitments", status: "in_progress")
    assert_response :success
  end

  test "list_commitments filtered by policy_area" do
    mcp_initialize
    mcp_call("list_commitments", policy_area: "defence")
    assert_response :success
  end

  test "list_commitments filtered by department" do
    mcp_initialize
    mcp_call("list_commitments", department: "finance")
    assert_response :success
  end

  test "list_commitments with search query" do
    mcp_initialize
    mcp_call("list_commitments", q: "defence")
    assert_response :success
  end

  test "list_commitments with pagination" do
    mcp_initialize
    mcp_call("list_commitments", page: 1, per_page: 2)
    assert_response :success
  end

  test "get_commitment" do
    mcp_initialize
    mcp_call("get_commitment", id: commitments(:defence_spending).id)
    assert_response :success
  end

  test "get_commitment not found" do
    mcp_initialize
    mcp_call("get_commitment", id: 999999)
    assert_response :success
  end

  # -- Departments --

  test "list_departments" do
    mcp_initialize
    mcp_call("list_departments")
    assert_response :success
  end

  test "get_department by slug" do
    mcp_initialize
    mcp_call("get_department", id_or_slug: "finance")
    assert_response :success
  end

  test "get_department by id" do
    mcp_initialize
    mcp_call("get_department", id_or_slug: departments(:finance).id.to_s)
    assert_response :success
  end

  test "get_department not found" do
    mcp_initialize
    mcp_call("get_department", id_or_slug: "nonexistent-slug")
    assert_response :success
  end

  # -- Promises --

  test "list_promises" do
    mcp_initialize
    mcp_call("list_promises")
    assert_response :success
  end

  test "get_promise" do
    mcp_initialize
    mcp_call("get_promise", id: promises(:one).id)
    assert_response :success
  end

  test "get_promise not found" do
    mcp_initialize
    mcp_call("get_promise", id: 999999)
    assert_response :success
  end

  # -- Bills --

  test "list_bills" do
    mcp_initialize
    mcp_call("list_bills")
    assert_response :success
  end

  test "get_bill" do
    mcp_initialize
    mcp_call("get_bill", id: bills(:one).id)
    assert_response :success
  end

  test "get_bill not found" do
    mcp_initialize
    mcp_call("get_bill", id: 999999)
    assert_response :success
  end

  # -- Ministers --

  test "list_ministers" do
    mcp_initialize
    mcp_call("list_ministers")
    assert_response :success
  end

  # -- Feed Items --

  test "list_activity with no filters" do
    mcp_initialize
    mcp_call("list_activity")
    assert_response :success
  end

  test "list_activity filtered by commitment" do
    mcp_initialize
    mcp_call("list_activity", commitment_id: commitments(:defence_spending).id)
    assert_response :success
  end

  test "list_activity filtered by date range" do
    mcp_initialize
    mcp_call("list_activity", since: "2025-01-01", until: "2025-12-31")
    assert_response :success
  end

  # -- Dashboard & Burndown --

  test "get_commitment_summary" do
    mcp_initialize
    mcp_call("get_commitment_summary", government_id: governments(:canada).id)
    assert_response :success
  end

  test "get_commitment_summary not found" do
    mcp_initialize
    mcp_call("get_commitment_summary", government_id: 999999)
    assert_response :success
  end

  test "get_commitment_progress" do
    mcp_initialize
    mcp_call("get_commitment_progress", government_id: governments(:canada).id)
    assert_response :success
  end

  test "get_commitment_progress with filters" do
    mcp_initialize
    mcp_call("get_commitment_progress", government_id: governments(:canada).id, policy_area_slug: "defence")
    assert_response :success
  end

  test "get_commitment_progress not found" do
    mcp_initialize
    mcp_call("get_commitment_progress", government_id: 999999)
    assert_response :success
  end
end
