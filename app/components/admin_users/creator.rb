# frozen_string_literal: true

# Creates an AdminUser.
#
#   result = AdminUsers::Creator.call(email: "a@b.c", password: "s3cret")
#   result.success? # => true
#   result.value    # => the created AdminUser
#   result.errors   # => validation messages on failure
class AdminUsers::Creator < ApplicationComponent
  def initialize(attributes)
    @attributes = attributes
  end

  def call
    admin_user = ::AdminUser.new(@attributes)

    return failure(admin_user.errors) unless admin_user.save

    success(admin_user)
  end
end
