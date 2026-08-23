# frozen_string_literal: true

module Api
  module V1
    # Platform-admin sessions: opaque bearer tokens, stored as digests.
    class AdminSessionsController < BaseController
      before_action :authenticate_admin_session!, only: %i[show destroy]

      # POST /api/v1/admin_sessions { email:, password: } → { token:, ... }
      # (the raw token is returned exactly once)
      def create
        admin = AdminUser.find_by(email: params[:email].to_s.strip.downcase)
        return render_unauthorized("Invalid email or password") unless admin&.valid_password?(params[:password])

        result = AdminSessions::Creator.call(platform_admin: admin, request: request)
        return render_result_error(result) if result.failure?

        issued = result.value
        render json: {
          token: issued.raw_token,
          token_type: "Bearer",
          expires_at: issued.session.expires_at.iso8601,
          platform_admin: { id: admin.id, email: admin.email }
        }, status: :created
      end

      # GET /api/v1/admin_sessions/validate — bearer token
      def show
        render json: session_json(@current_admin_session)
      end

      # DELETE /api/v1/admin_sessions/current — bearer token; revokes it
      def destroy
        AdminSessions::Revoker.call(@current_admin_session)

        head :no_content
      end

      private

      def session_json(session)
        {
          id: session.id,
          platform_admin_id: session.platform_admin_id,
          issuing_env: session.issuing_env,
          ip_address: session.ip_address,
          user_agent: session.user_agent,
          last_seen_at: session.last_seen_at,
          last_seen_ip: session.last_seen_ip,
          expires_at: session.expires_at.iso8601,
          revoked_at: session.revoked_at
        }
      end
    end
  end
end
