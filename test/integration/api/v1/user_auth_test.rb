# frozen_string_literal: true

require "test_helper"

class Api::V1::UserAuthTest < ActionDispatch::IntegrationTest
  test "sign up → sign in → me → sign out → me fails" do
    # Sign up
    post "/api/v1/sign_up", params: { email: "newbie@example.com", password: "s3cret-pw" }, as: :json
    assert_response :created
    assert_equal "newbie@example.com", response.parsed_body["email"]

    # Sign up again with the same email fails
    post "/api/v1/sign_up", params: { email: "newbie@example.com", password: "s3cret-pw" }, as: :json
    assert_response :unprocessable_content

    # Sign in
    post "/api/v1/sign_in", params: { email: "newbie@example.com", password: "s3cret-pw" }, as: :json
    assert_response :success
    token = response.parsed_body["token"]
    assert token.present?

    # Wrong password
    post "/api/v1/sign_in", params: { email: "newbie@example.com", password: "wrong" }, as: :json
    assert_response :unauthorized
    assert_equal "Invalid email or password", response.parsed_body["error"]

    post "/api/v1/sign_in", params: { email: "newbie@example.com", password: "wrong" },
      headers: { "Accept-Language" => "en;q=0.5,es-MX;q=1" }, as: :json
    assert_response :unauthorized
    assert_equal "Correo electrónico o contraseña no válidos", response.parsed_body["error"]
    assert_equal "es", response.headers["Content-Language"]

    post "/api/v1/sign_in?locale=en", params: { email: "newbie@example.com", password: "wrong" },
      headers: { "Accept-Language" => "es" }, as: :json
    assert_response :unauthorized
    assert_equal "Invalid email or password", response.parsed_body["error"]
    assert_equal "en", response.headers["Content-Language"]

    # Me with the token
    get "/api/v1/me", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert_equal "newbie@example.com", response.parsed_body["email"]

    # Me without / with a bad token
    get "/api/v1/me"
    assert_response :unauthorized
    get "/api/v1/me", headers: { "Authorization" => "Bearer garbage" }
    assert_response :unauthorized

    # Sign out revokes the token immediately
    delete "/api/v1/sign_out", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :no_content
    get "/api/v1/me", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :unauthorized
  end
end
