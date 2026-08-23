# frozen_string_literal: true

module Api
  module V1
    class SessionsController < BaseController
      before_action :authenticate_user!, only: :destroy

      # POST /api/v1/sign_in { email:, password: } → { token:, expires_at:, user: }
      def create
        result = Users::Authenticator.call(params[:email], params[:password])
        return render_unauthorized(result.error) if result.failure?

        issued = UserSessions::Creator.call(user: result.value, request: request)
        return render_result_error(issued) if issued.failure?

        render json: {
          token: issued.value.token,
          token_type: "Bearer",
          expires_at: issued.value.session.expires_at.iso8601,
          user: { id: result.value.id, email: result.value.email }
        }
      end

      # DELETE /api/v1/sign_out — bearer JWT; revokes the current session
      def destroy
        UserSessions::Revoker.call(@current_user_session)

        head :no_content
      end
    end
  end
end
