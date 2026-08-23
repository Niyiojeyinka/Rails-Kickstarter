# frozen_string_literal: true

# Creates a user session backed by a JWT. The session row is the source of
# truth (revoke it and the token dies before its exp).
#
#   result = UserSessions::Creator.call(user: user, request: request)
#   result.value.session # => the persisted UserSession
#   result.value.token   # => the JWT to hand to the client
class UserSessions::Creator < ApplicationComponent
  def initialize(user:, request: nil, issuing_env: Rails.env, ttl: UserSession.ttl)
    @user = user
    @request = request
    @issuing_env = issuing_env
    @ttl = ttl
  end

  def call
    session = UserSession.new(
      user: @user,
      jti: SecureRandom.uuid,
      issuing_env: @issuing_env,
      ip_address: @request&.remote_ip,
      user_agent: TokenDigest.truncate_ua(@request&.user_agent),
      last_seen_at: Time.current,
      last_seen_ip: @request&.remote_ip,
      expires_at: Time.current + @ttl
    )

    return failure(session.errors) unless session.save

    success(UserSessions::Issued.new(session: session, token: UserSession.issue_jwt(session)))
  end
end
