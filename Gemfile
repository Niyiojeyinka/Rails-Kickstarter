source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3", ">= 8.1.3.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# ---- Application gems ----

# Admin panel (ActiveAdmin 4 beta is the Rails 8-native line; see docs/OBSERVABILITY.md-style notes in README)
gem "activeadmin", "4.0.0.beta22"
gem "devise", "~> 5.0"

# CSS build pipeline: compiles the app + ActiveAdmin Tailwind entrypoints (Node required at build time)
gem "cssbundling-rails"

# Feature flags (ActiveRecord-backed, cached via Rails.cache — Solid Cache)
gem "flipper", "~> 1.4"
gem "flipper-active_record", "~> 1.4"
gem "flipper-active_support_cache_store", "~> 1.4"
gem "flipper-ui", "~> 1.4"

# Observability: OpenTelemetry tracing (OTLP) + Prometheus metrics (Yabeda)
gem "opentelemetry-sdk"
gem "opentelemetry-exporter-otlp"
gem "opentelemetry-instrumentation-all"
gem "yabeda-rails"
gem "yabeda-puma-plugin"
gem "yabeda-prometheus"
# WEBrick is not bundled with Ruby >= 3.0 but yabeda-prometheus uses it for
# its standalone metrics server.
gem "webrick"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# JSON Web Tokens for user sessions
gem "jwt", "~> 3.2"

# GraphQL API
gem "graphql", "~> 2.5"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # Loads .env / .env.development / .env.test (see .env.sample)
  gem "dotenv-rails"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # GraphQL IDE at /graphiql (development only)
  gem "graphiql-rails", "~> 1.10"

  # Open outgoing emails in the browser instead of sending them
  gem "letter_opener"

  # Warn about N+1 queries and unused eager loading
  gem "bullet"

  # Flamegraphs + SQL insights in the browser toolbar (development only)
  gem "rack-mini-profiler"

  # Annotate models/specs/fixtures with the schema
  gem "annotaterb"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Test factories (test/factories)
  gem "factory_bot_rails"

  # Fake data generators for factories
  gem "faker"

  # Mocking/stubbing on any object
  gem "mocha"

  # Prettier test output (SpecReporter in test_helper)
  gem "minitest-reporters"

  # Coverage reports (HTML + Cobertura for CI)
  gem "simplecov", require: false
  gem "simplecov-cobertura", require: false
end
