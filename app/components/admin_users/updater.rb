# frozen_string_literal: true

# Updates an existing AdminUser's attributes.
#
#   result = AdminUsers::Updater.call(admin_user, email: "new@b.c")
#   result.success? # => true
#   result.value    # => the updated AdminUser
class AdminUsers::Updater < ApplicationComponent
  def initialize(admin_user, attributes)
    @admin_user = admin_user
    @attributes = attributes
  end

  def call
    return failure(@admin_user.errors) unless @admin_user.update(@attributes)

    success(@admin_user)
  end
end
