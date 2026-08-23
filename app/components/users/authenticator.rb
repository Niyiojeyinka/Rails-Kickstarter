# frozen_string_literal: true

# Verifies a user's email + password for sign-in.
#
#   result = Users::Authenticator.call("a@b.c", "s3cret")
#   result.value # => the User, or result.failure? with a generic message
class Users::Authenticator < ApplicationComponent
  def initialize(email, password)
    @email = email
    @password = password
  end

  def call
    user = ::User.find_by(email: @email.to_s.strip.downcase)
    return failure(I18n.t("components.errors.invalid_credentials")) unless user&.authenticate(@password)

    success(user)
  end
end
