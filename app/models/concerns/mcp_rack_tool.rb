module McpRackTool
  extend ActiveSupport::Concern

  class_methods do
    def path_template(value = nil)
      if value
        @path_template = value
        @path_params = value.scan(/:(\w+)/).flatten.map(&:to_sym)
      else
        @path_template
      end
    end

    def path_params
      @path_params || []
    end

    def call(server_context:, **params)
      path = path_template.gsub(/:(\w+)/) { params[$1.to_sym] }
      query_params = params.except(*path_params)
      response = rack_get(path, query_params)
      MCP::Tool::Response.new([{ type: "text", text: response }])
    end

    private

    def rack_get(path, params = {})
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
end
