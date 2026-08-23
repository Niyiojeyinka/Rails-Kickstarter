# frozen_string_literal: true

require "test_helper"

class AdminUsers::DeleterTest < ActiveSupport::TestCase
  test "destroys the admin user" do
    admin_user = admin_users(:one)

    result = AdminUsers::Deleter.call(admin_user)

    assert_predicate result, :success?
    assert_nil result.value
    assert_not AdminUser.exists?(admin_user.id)
  end

  test "fails when the admin user was already destroyed" do
    admin_user = admin_users(:one)
    admin_user.destroy

    result = AdminUsers::Deleter.call(admin_user)

    assert_predicate result, :failure?
    assert_equal "Admin user has already been deleted", result.error
  end
end
