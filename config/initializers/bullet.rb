# frozen_string_literal: true

# N+1 query detection (development only). Alerts appear in the browser
# console, logs, and the Bullet debug window when enabled.
if defined?(Bullet) && Rails.env.development?
  Bullet.enable = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true
end
