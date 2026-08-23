# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: admin_sessions
#
#  id                :bigint           not null, primary key
#  expires_at        :datetime         not null
#  ip_address        :string
#  issuing_env       :string           not null
#  last_seen_at      :datetime
#  last_seen_ip      :string
#  revoked_at        :datetime
#  token_digest      :string           not null
#  user_agent        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  platform_admin_id :bigint           not null
#
# Indexes
#
#  index_admin_sessions_on_platform_admin_id  (platform_admin_id)
#  index_admin_sessions_on_token_digest       (token_digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (platform_admin_id => admin_users.id)
#
class AdminSessionTest < ActiveSupport::TestCase
  test "active until revoked or expired" do
    session = AdminSession.new(platform_admin: admin_users(:one), token_digest: "x", issuing_env: "test", expires_at: 1.hour.from_now)
    assert_predicate session, :active?

    session.revoked_at = Time.current
    assert_predicate session, :revoked?
    assert_not_predicate session, :active?

    session.revoked_at = nil
    session.expires_at = 1.hour.ago
    assert_predicate session, :expired?
    assert_not_predicate session, :active?
  end

  test "revoke! stamps revoked_at" do
    session = AdminSessions::Creator.call(platform_admin: admin_users(:one)).value.session

    AdminSessions::Revoker.call(session)

    assert session.reload.revoked_at.present?
  end

  test "touch_seen! updates last seen from the request" do
    session = AdminSessions::Creator.call(platform_admin: admin_users(:one)).value.session
    request = ActionDispatch::TestRequest.create

    session.touch_seen!(request)

    assert session.reload.last_seen_at.present?
    assert_equal request.remote_ip, session.reload.last_seen_ip
  end

  test "ttl defaults to 30 days and is env-overridable" do
    assert_equal 30.days, AdminSession.ttl

    with_env("ADMIN_SESSION_TTL" => "3600") do
      assert_equal 1.hour, AdminSession.ttl
    end
  end
end
