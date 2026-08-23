# frozen_string_literal: true

# Creates a platform-admin session backed by an opaque bearer token.
#
#   result = AdminSessions::Creator.call(platform_admin: admin, request: request)
#   result.value.session    # => the persisted AdminSession
#   result.value.raw_token  # => shown once; store it on the client
class AdminSessions::Creator < ApplicationComponent
  def initialize(platform_admin:, request: nil, issuing_env: Rails.env, ttl: AdminSession.ttl)
    @platform_admin = platform_admin
    @request = request
    @issuing_env = issuing_env
    @ttl = ttl
  end

  def call
    raw_token = TokenDigest.generate

    session = AdminSession.new(
      platform_admin: @platform_admin,
      token_digest: TokenDigest.digest(raw_token),
      issuing_env: @issuing_env,
      ip_address: @request&.remote_ip,
      user_agent: TokenDigest.truncate_ua(@request&.user_agent),
      last_seen_at: Time.current,
      last_seen_ip: @request&.remote_ip,
      expires_at: Time.current + @ttl
    )

    return failure(session.errors) unless session.save

    success(AdminSessions::Issued.new(session: session, raw_token: raw_token))
  end
end
