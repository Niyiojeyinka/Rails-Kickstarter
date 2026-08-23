# frozen_string_literal: true

require "test_helper"

class AdminUsers::CreatorTest < ActiveSupport::TestCase
  test "creates an admin user and returns it in the result" do
    result = AdminUsers::Creator.call(email: "new@example.com", password: "s3cret-pw")

    assert_predicate result, :success?
    assert_equal "new@example.com", result.value.email
    assert AdminUser.exists?(result.value.id)
  end

  test "returns validation errors when the email is invalid" do
    result = AdminUsers::Creator.call(email: "nope", password: "s3cret-pw")

    assert_predicate result, :failure?
    assert_includes result.errors, "Email is invalid"
    assert_equal 2, AdminUser.count
  end

  test "returns validation errors when attributes are missing" do
    result = AdminUsers::Creator.call({})

    assert_predicate result, :failure?
    assert_includes result.errors, "Email can't be blank"
    assert_includes result.errors, "Password can't be blank"
  end
end
