module Api
  module Agent
    class BaseController < ActionController::API
      before_action :authenticate_agent

      private

      def authenticate_agent
        token = request.headers["Authorization"]&.delete_prefix("Bearer ")
        expected = Rails.application.credentials.dig(:agent, :api_key) || ENV["AGENT_API_KEY"]

        unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected.to_s)
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end
    end
  end
end
