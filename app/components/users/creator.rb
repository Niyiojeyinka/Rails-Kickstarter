# frozen_string_literal: true

# Creates a User (email + password, has_secure_password).
#
#   result = Users::Creator.call(email: "a@b.c", password: "s3cret")
#   result.value # => the created User
class Users::Creator < ApplicationComponent
  def initialize(attributes)
    @attributes = attributes
  end

  def call
    user = ::User.new(@attributes)

    return failure(user.errors) unless user.save

    success(user)
  end
end
