# A user session, authenticated with a JWT bearer token.
#
# The JWT carries { sub, jti, iss, iat, exp }; this row is the source of truth
# for revocation — deleting or revoking it invalidates the token even before
# expiry. Sessions track where they were issued from and last-seen activity.
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
class UserSession < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(revoked_at: nil).where(expires_at: Time.current...) }

  # Default session lifetime; override with the USER_SESSION_TTL env var (seconds).
  def self.ttl
    ENV.fetch("USER_SESSION_TTL", 30.days.to_i).to_i.seconds
  end

  # HMAC secret used to sign tokens. Defaults to the Rails secret_key_base;
  # set JWT_SECRET to decouple signing from the session cookie secret.
  def self.secret
    ENV.fetch("JWT_SECRET", Rails.application.secret_key_base)
  end

  def self.issue_jwt(session)
    payload = {
      sub: session.user_id,
      jti: session.jti,
      iss: session.issuing_env,
      iat: session.created_at.to_i,
      exp: session.expires_at.to_i
    }

    JWT.encode(payload, secret, "HS256")
  end

  # Decodes and verifies a token. Raises JWT::DecodeError / JWT::ExpiredSignature
  # on invalid, tampered, or expired tokens.
  def self.decode_jwt(token)
    JWT.decode(token, secret, true, algorithm: "HS256").first
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
