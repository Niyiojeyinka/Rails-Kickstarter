# frozen_string_literal: true

# Authenticates a platform-admin bearer token against AdminSession records.
#
#   result = AdminSessions::Authenticator.call(request.headers["Authorization"])
#   result.value # => the active AdminSession (last_seen touched)
class AdminSessions::Authenticator < ApplicationComponent
  def initialize(raw_token)
    @raw_token = raw_token
  end

  def call
    return failure(I18n.t("components.errors.token_required")) if @raw_token.blank?

    session = AdminSession.active.find_by(token_digest: TokenDigest.digest(@raw_token))
    return failure(I18n.t("components.errors.invalid_or_expired_session")) unless session

    session.touch_seen!

    success(session)
  end
end
