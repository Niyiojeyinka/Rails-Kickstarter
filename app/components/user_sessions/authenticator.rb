# frozen_string_literal: true

# Authenticates a user JWT: verifies the signature, checks expiry, and
# confirms the session row (jti) is still active — so revoked sessions die
# immediately, before their exp.
#
#   result = UserSessions::Authenticator.call(request.headers["Authorization"])
#   result.value # => the active UserSession (last_seen touched)
class UserSessions::Authenticator < ApplicationComponent
  def initialize(token)
    @token = token
  end

  def call
    return failure("Token is required") if @token.blank?

    payload = UserSession.decode_jwt(@token)
    session = UserSession.active.find_by(jti: payload["jti"])
    return failure("Session revoked or expired") unless session

    session.touch_seen!

    success(session)
  rescue JWT::DecodeError
    # Signature mismatch, malformed token, or expired (ExpiredSignature < DecodeError).
    failure("Invalid token")
  end
end
