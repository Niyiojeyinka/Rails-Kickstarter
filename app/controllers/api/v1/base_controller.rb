# frozen_string_literal: true

module Api
  module V1
    # JSON API base: bearer-token auth helpers shared by all V1 endpoints.
    class BaseController < ApplicationController
      # The API is authenticated with bearer tokens, not cookies, so there is
      # no session to forge against.
      protect_from_forgery with: :null_session

      private

      def bearer_token
        header = request.headers["Authorization"].to_s
        header[/\ABearer (.+)\z/, 1]
      end

      # Halts with 401 unless the bearer token maps to an active UserSession.
      def authenticate_user!
        result = UserSessions::Authenticator.call(bearer_token)
        return render_unauthorized(result.error) if result.failure?

        @current_user_session = result.value
        @current_user = result.value.user
      end

      # Halts with 401 unless the bearer token maps to an active AdminSession.
      def authenticate_admin_session!
        result = AdminSessions::Authenticator.call(bearer_token)
        return render_unauthorized(result.error) if result.failure?

        @current_admin_session = result.value
      end

      def render_unauthorized(message)
        render json: { error: message }, status: :unauthorized
      end

      def render_result_error(result)
        render json: { errors: result.errors }, status: :unprocessable_content
      end
    end
  end
end
