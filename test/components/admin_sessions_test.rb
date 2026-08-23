# frozen_string_literal: true

require "test_helper"

class AdminSessionsTest < ActiveSupport::TestCase
  test "creator stores a digest, never the raw token, and tracks request metadata" do
    request = ActionDispatch::TestRequest.create("HTTP_USER_AGENT" => "SpecRunner/1.0")
    admin = admin_users(:one)

    result = AdminSessions::Creator.call(platform_admin: admin, request: request)

    assert_predicate result, :success?
    issued = result.value
    assert issued.raw_token.present?

    session = issued.session
    assert_equal TokenDigest.digest(issued.raw_token), session.token_digest
    assert_not_equal issued.raw_token, session.token_digest
    assert_equal "test", session.issuing_env
    assert_equal request.remote_ip, session.ip_address
    assert_includes session.user_agent, "SpecRunner"
    assert session.expires_at > Time.current
    assert AdminSession.exists?(session.id)
  end

  test "creator stamps last_seen and expiry from the current time (mocha demo)" do
    now = Time.utc(2026, 8, 23, 12, 0, 0)
    Time.stubs(:current).returns(now)

    session = AdminSessions::Creator.call(platform_admin: admin_users(:one)).value.session

    assert_equal now, session.last_seen_at
    assert_equal now + AdminSession.ttl, session.expires_at
  end

  test "authenticator accepts the raw token and touches last_seen" do
    issued = AdminSessions::Creator.call(platform_admin: admin_users(:one)).value

    result = AdminSessions::Authenticator.call(issued.raw_token)

    assert_predicate result, :success?
    assert_equal issued.session.id, result.value.id
    assert result.value.last_seen_at.present?
  end

  test "authenticator rejects blank, unknown, revoked, and expired tokens" do
    assert_predicate AdminSessions::Authenticator.call(nil), :failure?
    assert_predicate AdminSessions::Authenticator.call("unknown-token"), :failure?

    issued = AdminSessions::Creator.call(platform_admin: admin_users(:one)).value
    AdminSessions::Revoker.call(issued.session)
    assert_predicate AdminSessions::Authenticator.call(issued.raw_token), :failure?

    expired = AdminSessions::Creator.call(platform_admin: admin_users(:one), ttl: 1.minute).value
    expired.session.update!(expires_at: 1.hour.ago)
    assert_predicate AdminSessions::Authenticator.call(expired.raw_token), :failure?
  end

  test "revoker invalidates the token and is idempotent" do
    session = AdminSessions::Creator.call(platform_admin: admin_users(:one)).value.session

    assert_predicate AdminSessions::Revoker.call(session), :success?
    assert_predicate AdminSessions::Revoker.call(session), :failure?
    assert_equal "Session is already revoked", AdminSessions::Revoker.call(session).error
  end
end
