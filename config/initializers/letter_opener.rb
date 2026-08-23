# frozen_string_literal: true

# Open outgoing emails in the browser instead of delivering them (development).
Rails.application.configure do
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
end if Rails.env.development? && defined?(LetterOpener)
