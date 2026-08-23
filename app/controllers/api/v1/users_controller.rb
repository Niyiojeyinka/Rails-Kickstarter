# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :authenticate_user!, only: :me

      # POST /api/v1/sign_up { email:, password: }
      def create
        result = Users::Creator.call(params.permit(:email, :password))

        return render_result_error(result) if result.failure?

        render json: user_json(result.value), status: :created
      end

      # GET /api/v1/me — bearer JWT
      def me
        render json: user_json(@current_user)
      end

      private

      def user_json(user)
        { id: user.id, email: user.email }
      end
    end
  end
end
