# frozen_string_literal: true

# Helpers for opaque bearer tokens (admin sessions). Raw tokens are shown to
# the caller once; only their SHA-256 digest is stored.
module TokenDigest
  module_function

  def generate(length = 32)
    SecureRandom.urlsafe_base64(length)
  end

  def digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  # Long user-agent strings are useless for audit purposes; keep a prefix.
  def truncate_ua(user_agent, limit: 255)
    user_agent.to_s.truncate(limit)
  end
end
