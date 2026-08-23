# frozen_string_literal: true

require "test_helper"

class ApplicationComponent::ResultTest < ActiveSupport::TestCase
  test "success result reports success and carries the value" do
    user = Object.new
    result = ApplicationComponent::Result.success(user)

    assert_predicate result, :success?
    assert_not_predicate result, :failure?
    assert_same user, result.value
    assert_empty result.errors
  end

  test "failure result reports failure and carries errors" do
    result = ApplicationComponent::Result.failure([ "Email is invalid" ])

    assert_predicate result, :failure?
    assert_not_predicate result, :success?
    assert_nil result.value
    assert_equal [ "Email is invalid" ], result.errors
    assert_equal "Email is invalid", result.error
  end

  test "failure wraps a single error string in an array" do
    assert_equal [ "boom" ], ApplicationComponent::Result.failure("boom").errors
  end

  test "failure accepts ActiveModel::Errors" do
    errors = ActiveModel::Errors.new(AdminUser.new)
    errors.add(:email, "is invalid")

    assert_equal [ "Email is invalid" ], ApplicationComponent::Result.failure(errors).errors
  end
end
