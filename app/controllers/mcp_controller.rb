class McpController < ActionController::API
  # Each MCP tool maps 1:1 to an existing REST endpoint. All data access and
  # serialization is handled by the existing controllers and Jbuilder views.
  TOOLS_CONFIG = [
    {
      name: "list_policy_areas",
      path: "/policy_areas",
      description: <<~DESC.strip,
        List all policy areas (e.g. Defence, Healthcare, Economy) with their slugs.
        Use this first to discover valid policy_area slugs for filtering other tools.
        Returns: id, name, slug, description, position. There are ~16 policy areas.
      DESC
    },
    {
      name: "list_commitments",
      path: "/commitments",
      description: <<~DESC.strip,
        Search and filter government commitments — the core accountability tracking unit.
        The Build Canada data model: Promises (raw political pledges) → Commitments
        (specific, measurable outcomes with status tracking) → Evidence (bills, events, sources).
        Each commitment has a status (not_started/in_progress/completed/broken), a type,
        a policy area, and a lead department. Returns paginated results with
        criteria_count, matches_count, and meta { total_count, page, per_page }.
        Use list_policy_areas to discover valid policy_area slugs.
      DESC
      properties: {
        q: { type: "string", description: "Full-text search on title and description" },
        status: { type: "string", enum: %w[not_started in_progress completed broken], description: "Filter by commitment status" },
        policy_area: { type: "string", description: "Policy area slug — use list_policy_areas to see valid values" },
        commitment_type: { type: "string", enum: %w[legislative spending procedural institutional diplomatic aspirational outcome], description: "Filter by commitment type" },
        department: { type: "string", description: "Department slug (e.g. 'finance-canada')" },
        stale_days: { type: "integer", description: "Only commitments not assessed in this many days" },
        sort: { type: "string", enum: %w[title date_promised last_assessed_at status], description: "Sort field (default: created_at desc)" },
        direction: { type: "string", enum: %w[asc desc], description: "Sort direction (default: desc)" },
        page: { type: "integer", description: "Page number (default: 1)" },
        per_page: { type: "integer", description: "Results per page, max 1000 (default: 50)" }
      }
    },
    {
      name: "get_commitment",
      path: "/commitments/:id",
      description: <<~DESC.strip,
        Get full details for a single commitment. Returns all nested data: sources
        (original government documents), criteria (completion/success/progress/failure
        with assessment history), matches (linked bills and entries with relevance scores),
        departments, timeline events, status_history, and recent_feed items.
      DESC
      properties: { id: { type: "integer", description: "The commitment ID" } },
      required: [ "id" ]
    },
    {
      name: "list_promises",
      path: "/promises",
      description: <<~DESC.strip,
        List all platform promises — the original political pledges from the 2025 campaign
        platform, mandate letters, and budgets. There are ~350 promises. Each has a
        concise_title, progress_score (1-5), and bc_promise_rank. Promises are upstream
        of commitments: a promise like "increase defence spending" may generate several
        specific commitments with measurable criteria. Returns all promises (no pagination).
      DESC
    },
    {
      name: "get_promise",
      path: "/promises/:id",
      description: <<~DESC.strip,
        Get full details for a single promise. Returns: text, description,
        what_it_means_for_canadians, commitment_history_rationale, progress_score,
        progress_summary, source_url, and evidences — impactful evidence links with
        impact assessment and linked government activity details.
      DESC
      properties: { id: { type: "integer", description: "The promise ID" } },
      required: [ "id" ]
    },
    {
      name: "list_bills",
      path: "/bills",
      description: <<~DESC.strip,
        List Canadian parliamentary bills (45th Parliament). Returns bill_number_formatted
        (e.g. 'C-2', 'S-201'), short_title, long_title, latest_activity, and all stage
        dates tracking progress through Parliament: House 1st/2nd/3rd reading, Senate
        1st/2nd/3rd reading, and Royal Assent. Filter to government bills to exclude
        private members' bills.
      DESC
      properties: {
        parliament_number: { type: "integer", description: "Filter by parliament (e.g. 45 for current)" },
        government_bills: { type: "string", enum: %w[true], description: "Set to 'true' to only return House/Senate Government Bills" }
      }
    },
    {
      name: "get_bill",
      path: "/bills/:id",
      description: <<~DESC.strip,
        Get full details for a parliamentary bill. Returns all stage dates, the complete
        raw data from the Parliament of Canada API (sponsor, type, session info), and
        linked_commitments — which government commitments this bill implements, with
        relevance scores and reasoning.
      DESC
      properties: { id: { type: "integer", description: "The bill database ID" } },
      required: [ "id" ]
    },
    {
      name: "list_departments",
      path: "/departments",
      description: <<~DESC.strip,
        List all ~32 federal government departments. Returns: id, display_name, slug,
        official_name, priority, and minister info (name, title, contact details,
        hill office) if a minister is assigned.
      DESC
    },
    {
      name: "get_department",
      path: "/departments/:id_or_slug",
      description: <<~DESC.strip,
        Get department details including minister info (hill office, constituency offices)
        and the department's lead promises with progress scores. Accepts numeric ID or
        slug (e.g. 'finance-canada', 'national-defence').
      DESC
      properties: { id_or_slug: { type: "string", description: "Department ID or slug" } },
      required: [ "id_or_slug" ]
    },
    {
      name: "list_ministers",
      path: "/ministers",
      description: <<~DESC.strip,
        List current cabinet ministers and officials. Returns: name, title, avatar_url,
        email, phone, website, constituency, province, and their department assignment.
      DESC
    },
    {
      name: "list_activity",
      path: "/feed",
      description: <<~DESC.strip,
        Chronological feed of government activity on tracked commitments. Best tool for
        "what's happening" or "what changed recently." Returns: event_type, title, summary,
        occurred_at, linked commitment, and policy_area. Paginated, most recent first.
        Note: only populated when the evaluation agent has assessed commitments and
        created events — will be empty if no commitments have been evaluated yet.
      DESC
      properties: {
        commitment_id: { type: "integer", description: "Filter to one commitment's activity" },
        event_type: { type: "string", description: "Filter by event type" },
        policy_area_id: { type: "integer", description: "Filter by policy area ID" },
        since: { type: "string", description: "Activity after this date (ISO 8601, e.g. '2025-06-01')" },
        until: { type: "string", description: "Activity before this date (ISO 8601)" },
        page: { type: "integer", description: "Page number (default: 1)" },
        per_page: { type: "integer", description: "Results per page, max 100 (default: 50)" }
      }
    },
    {
      name: "get_commitment_summary",
      path: "/api/dashboard/:government_id/at_a_glance",
      description: <<~DESC.strip,
        Overall commitment status summary — how many commitments are not started, in progress,
        completed, or broken, broken down by policy area. This aggregates COMMITMENTS (not
        promises). If no commitments exist yet, totals will be zero even if promises are loaded.
        The government_id for the current Government of Canada is 1.
      DESC
      properties: {
        government_id: { type: "integer", description: "Government ID (1 = current Government of Canada)" },
        source_type: { type: "string", description: "Filter by source type (e.g. 'platform_document', 'mandate_letter')" }
      },
      required: [ "government_id" ]
    },
    {
      name: "get_commitment_progress",
      path: "/api/burndown/:government_id",
      description: <<~DESC.strip,
        Commitment progress over time — daily time-series of how many commitments have been
        scoped, started, completed, or broken throughout a government's mandate. Useful for
        trend analysis and charting. Returns { date, scope, started, completed, broken } per
        day, plus mandate_start/end dates. Tracks COMMITMENTS (not promises).
        The government_id for the current Government of Canada is 1.
      DESC
      properties: {
        government_id: { type: "integer", description: "Government ID (1 = current Government of Canada)" },
        source_type: { type: "string", description: "Filter by source type" },
        policy_area_slug: { type: "string", description: "Filter by policy area slug" },
        department_slug: { type: "string", description: "Filter by lead department slug" }
      },
      required: [ "government_id" ]
    }
  ].freeze

  # Generate MCP::Tool subclasses from the config above.
  TOOLS = TOOLS_CONFIG.map do |config|
    path_template = config[:path]
    path_params = path_template.scan(/:(\w+)/).flatten.map(&:to_sym)

    klass = Class.new(MCP::Tool) do
      description config[:description]
      schema = { properties: config.fetch(:properties, {}) }
      schema[:required] = config[:required] if config[:required]&.any?
      input_schema(**schema)

      define_singleton_method(:call) do |server_context:, **params|
        path = path_template.gsub(/:(\w+)/) { params[$1.to_sym] }
        query_params = params.except(*path_params)
        response = McpController.internal_get(path, query_params)
        MCP::Tool::Response.new([{ type: "text", text: response }])
      end
    end

    # Register as a top-level constant so the mcp gem derives the tool name from the class name.
    const_name = config[:name].to_s.camelize
    Object.const_set(const_name, klass) unless Object.const_defined?(const_name)
    klass
  end.freeze

  def create
    server = MCP::Server.new(name: "build-canada-tracker", version: "1.0.0", tools: TOOLS)
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true)
    server.transport = transport

    resp_status, resp_headers, resp_body = transport.handle_request(request)
    resp_headers&.each { |key, value| response.headers[key] = value }
    render json: resp_body&.first, status: resp_status
  end

  # Internal Rack dispatch — lets MCP tools call existing REST endpoints
  # without duplicating any controller or query logic.
  def self.internal_get(path, params = {})
    query_string = params.compact.to_query
    url = query_string.empty? ? path : "#{path}?#{query_string}"

    env = Rack::MockRequest.env_for(url, "REQUEST_METHOD" => "GET", "HTTP_ACCEPT" => "application/json", "HTTP_HOST" => "localhost")
    status, headers, body = Rails.application.call(env)

    chunks = []
    body.each { |chunk| chunks << chunk }
    body.close if body.respond_to?(:close)
    chunks.join
  end
end
