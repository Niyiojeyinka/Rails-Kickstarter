# frozen_string_literal: true

require "test_helper"

class UsersTest < ActiveSupport::TestCase
  test "creator creates a user with a hashed password" do
    result = Users::Creator.call(email: "new@example.com", password: "s3cret-pw")

    assert_predicate result, :success?
    assert_equal "new@example.com", result.value.email
    assert result.value.authenticate("s3cret-pw")
    assert_not_equal "s3cret-pw", result.value.password_digest
  end

  test "creator returns validation errors" do
    result = Users::Creator.call(email: "nope", password: "")

    assert_predicate result, :failure?
    assert_includes result.errors, "Email is invalid"
    assert_includes result.errors, "Password can't be blank"
  end

  test "authenticator verifies email + password" do
    result = Users::Authenticator.call("USER_ONE@example.com", "password")

    assert_predicate result, :success?
    assert_equal users(:one).id, result.value.id
  end

  test "authenticator fails with the same message for wrong email or password" do
    wrong_email = Users::Authenticator.call("nobody@example.com", "password")
    wrong_password = Users::Authenticator.call("user_one@example.com", "wrong")

    assert_predicate wrong_email, :failure?
    assert_predicate wrong_password, :failure?
    assert_equal wrong_email.error, wrong_password.error
  end
end
