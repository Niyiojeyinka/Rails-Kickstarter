# frozen_string_literal: true

# Revokes a platform-admin session, invalidating its token immediately.
#
#   AdminSessions::Revoker.call(session)
class AdminSessions::Revoker < ApplicationComponent
  def initialize(session)
    @session = session
  end

  def call
    return failure("Session is already revoked") if @session.revoked?

    @session.revoke!

    success(nil)
  end
end
