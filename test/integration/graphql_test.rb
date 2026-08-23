# frozen_string_literal: true

require "test_helper"

class GraphqlTest < ActionDispatch::IntegrationTest
  test "queries users through POST /graphql" do
    post "/graphql", params: { query: "{ users { id email } }" }, as: :json

    assert_response :success
    emails = response.parsed_body.dig("data", "users").map { |user| user["email"] }
    assert_includes emails, users(:one).email
  end

  test "passes variables and operation names" do
    query = "query AllUsers { users { email } }"
    post "/graphql", params: { query: query, operationName: "AllUsers" }, as: :json

    assert_response :success
    assert response.parsed_body["data"]["users"].any?
  end

  test "returns errors for invalid queries" do
    post "/graphql", params: { query: "{ nope }" }, as: :json

    assert_response :success
    assert response.parsed_body["errors"].present?
  end
end
