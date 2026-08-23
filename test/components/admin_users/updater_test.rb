# frozen_string_literal: true

require "test_helper"

class AdminUsers::UpdaterTest < ActiveSupport::TestCase
  test "updates the admin user and returns it in the result" do
    admin_user = admin_users(:one)

    result = AdminUsers::Updater.call(admin_user, email: "updated@example.com")

    assert_predicate result, :success?
    assert_equal "updated@example.com", result.value.email
    assert_equal "updated@example.com", admin_user.reload.email
  end

  test "returns validation errors when the update is invalid" do
    admin_user = admin_users(:one)

    result = AdminUsers::Updater.call(admin_user, email: "")

    assert_predicate result, :failure?
    assert_includes result.errors, "Email can't be blank"
  end
end
