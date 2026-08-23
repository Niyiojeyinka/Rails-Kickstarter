# frozen_string_literal: true

require "rack"
require "rackup"

# Prometheus metrics via Yabeda.
#
# Rails request metrics come from yabeda-rails, Puma thread-pool metrics from
# the :yabeda plugin in config/puma.rb. Exposed at :METRICS_PORT/metrics
# (default 9394), bound to loopback and protected with HTTP Basic auth —
# Prometheus scrapes it with the same credentials (see
# config/prometheus/prometheus.yml and docs/OBSERVABILITY.md).
Yabeda.configure!

# Only the web server process exposes the metrics endpoint (console, runner,
# rake, and Solid Queue processes collect metrics but don't serve them).
if !Rails.env.test? && defined?(Rails::Server)
  app = Rack::Builder.new do
    use Rack::Auth::Basic, "Kickstart metrics" do |username, password|
      Rack::Utils.secure_compare(username, ENV.fetch("METRICS_AUTH_USERNAME", "prometheus")) &
        Rack::Utils.secure_compare(password, ENV.fetch("METRICS_AUTH_PASSWORD", "dev-metrics-password"))
    end

    run Yabeda::Prometheus::Exporter.rack_app
  end

  # Bind to loopback only; Prometheus (in Docker) still reaches it through
  # host.docker.internal.
  Thread.new do
    Rackup::Handler::WEBrick.run(
      app,
      Host: "127.0.0.1",
      Port: ENV.fetch("METRICS_PORT", 9394).to_i,
      AccessLog: []
    )
  end
end
