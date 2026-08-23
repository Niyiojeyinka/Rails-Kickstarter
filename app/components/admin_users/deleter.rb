# frozen_string_literal: true

# Deletes an AdminUser.
#
#   result = AdminUsers::Deleter.call(admin_user)
#   result.success? # => true (record destroyed; result.value is nil)
class AdminUsers::Deleter < ApplicationComponent
  def initialize(admin_user)
    @admin_user = admin_user
  end

  def call
    return failure("Admin user has already been deleted") unless @admin_user.persisted?

    @admin_user.destroy

    success(nil)
  end
end
