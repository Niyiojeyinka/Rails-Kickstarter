# frozen_string_literal: true

# Revokes a user session — the JWT stops working immediately, even though
# its exp is still in the future.
#
#   UserSessions::Revoker.call(session)
class UserSessions::Revoker < ApplicationComponent
  def initialize(session)
    @session = session
  end

  def call
    return failure("Session is already revoked") if @session.revoked?

    @session.revoke!

    success(nil)
  end
end
