# A platform-admin session, authenticated with an opaque bearer token.
#
# Only the SHA-256 digest of the token is stored — the raw token is returned
# to the caller once (AdminSessions::Creator) and must be presented on
# subsequent requests. Sessions track where they were issued from, are
# revocable, and expire after a TTL.
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
class AdminSession < ApplicationRecord
  # The ActiveAdmin user who owns this session.
  belongs_to :platform_admin, class_name: "AdminUser"

  scope :active, -> { where(revoked_at: nil).where(expires_at: Time.current...) }

  # Default session lifetime; override with the ADMIN_SESSION_TTL env var (seconds).
  def self.ttl
    ENV.fetch("ADMIN_SESSION_TTL", 30.days.to_i).to_i.seconds
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at.past?
  end

  def active?
    !revoked? && !expired?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_seen!(request = nil)
    update!(last_seen_at: Time.current, last_seen_ip: request&.remote_ip)
  end
end
