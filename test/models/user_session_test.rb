# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: user_sessions
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime         not null
#  ip_address   :string
#  issuing_env  :string           not null
#  jti          :string           not null
#  last_seen_at :datetime
#  last_seen_ip :string
#  revoked_at   :datetime
#  user_agent   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_user_sessions_on_jti      (jti) UNIQUE
#  index_user_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserSessionTest < ActiveSupport::TestCase
  test "issues a JWT that decodes back to the session" do
    session = UserSessions::Creator.call(user: users(:one)).value.session

    payload = UserSession.decode_jwt(UserSession.issue_jwt(session))

    assert_equal users(:one).id, payload["sub"]
    assert_equal session.jti, payload["jti"]
    assert_equal session.expires_at.to_i, payload["exp"]
  end

  test "rejects tampered tokens" do
    token = UserSessions::Creator.call(user: users(:one)).value.token
    tampered = token[0..-3] + (token[-2] == "a" ? "b" : "a")

    assert_raises(JWT::DecodeError) { UserSession.decode_jwt(tampered) }
  end

  test "rejects expired tokens" do
    session = UserSessions::Creator.call(user: users(:one)).value.session
    session.update!(expires_at: 1.hour.ago)

    # The exp claim lives in the token, so sign one against the expired row.
    expired_token = UserSession.issue_jwt(session)

    assert_raises(JWT::ExpiredSignature) { UserSession.decode_jwt(expired_token) }
  end

  test "ttl defaults to 30 days and is env-overridable" do
    assert_equal 30.days, UserSession.ttl

    with_env("USER_SESSION_TTL" => "7200") do
      assert_equal 2.hours, UserSession.ttl
    end
  end
end
