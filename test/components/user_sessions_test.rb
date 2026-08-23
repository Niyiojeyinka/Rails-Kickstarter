# frozen_string_literal: true

require "test_helper"

class UserSessionsTest < ActiveSupport::TestCase
  test "creator persists a session with a jti and issues a matching JWT" do
    request = ActionDispatch::TestRequest.create("HTTP_USER_AGENT" => "SpecRunner/1.0")

    result = UserSessions::Creator.call(user: users(:one), request: request)

    assert_predicate result, :success?
    issued = result.value
    assert issued.token.present?

    payload = UserSession.decode_jwt(issued.token)
    assert_equal users(:one).id, payload["sub"]
    assert_equal issued.session.jti, payload["jti"]
    assert_equal "test", issued.session.issuing_env
    assert_equal request.remote_ip, issued.session.ip_address
    assert_includes issued.session.user_agent, "SpecRunner"
  end

  test "authenticator accepts a valid token and touches last_seen" do
    issued = UserSessions::Creator.call(user: users(:one)).value

    result = UserSessions::Authenticator.call(issued.token)

    assert_predicate result, :success?
    assert_equal issued.session.id, result.value.id
    assert result.value.last_seen_at.present?
  end

  test "authenticator rejects blank, tampered, revoked, and expired tokens" do
    assert_predicate UserSessions::Authenticator.call(nil), :failure?

    issued = UserSessions::Creator.call(user: users(:one)).value
    tampered = issued.token[0..-3] + (issued.token[-2] == "a" ? "b" : "a")
    assert_predicate UserSessions::Authenticator.call(tampered), :failure?

    UserSessions::Revoker.call(issued.session)
    assert_predicate UserSessions::Authenticator.call(issued.token), :failure?

    expired = UserSessions::Creator.call(user: users(:one), ttl: 1.minute).value
    expired.session.update!(expires_at: 1.hour.ago)
    assert_predicate UserSessions::Authenticator.call(expired.token), :failure?
  end

  test "authenticator translates client-facing errors using the current locale" do
    result = I18n.with_locale(:es) { UserSessions::Authenticator.call(nil) }

    assert_equal "Se requiere un token", result.error
  end

  test "revoker invalidates the JWT immediately" do
    issued = UserSessions::Creator.call(user: users(:one)).value

    assert_predicate UserSessions::Revoker.call(issued.session), :success?
    assert_predicate UserSessions::Authenticator.call(issued.token), :failure?
  end
end
