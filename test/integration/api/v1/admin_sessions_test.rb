# frozen_string_literal: true

require "test_helper"

class Api::V1::AdminSessionsTest < ActionDispatch::IntegrationTest
  test "issue → validate → revoke an admin session" do
    admin = admin_users(:one)
    assert admin.valid_password?("password"), "fixture password must be 'password'"

    # Issue
    post "/api/v1/admin_sessions", params: { email: admin.email, password: "password" }, as: :json
    assert_response :created
    token = response.parsed_body["token"]
    assert token.present?
    assert_equal admin.email, response.parsed_body["platform_admin"]["email"]

    # Bad credentials
    post "/api/v1/admin_sessions", params: { email: admin.email, password: "wrong" }, as: :json
    assert_response :unauthorized

    # Validate
    get "/api/v1/admin_sessions/validate", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert_equal "test", response.parsed_body["issuing_env"]
    assert_equal admin.id, response.parsed_body["platform_admin_id"]

    # Revoke, then the token stops working
    delete "/api/v1/admin_sessions/current", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :no_content
    get "/api/v1/admin_sessions/validate", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :unauthorized
  end
end
