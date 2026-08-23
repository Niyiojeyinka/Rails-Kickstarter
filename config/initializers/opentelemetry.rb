# frozen_string_literal: true

require "opentelemetry/sdk"
require "opentelemetry/instrumentation/all"

# OpenTelemetry tracing. All settings are environment-driven:
#
#   OTEL_SERVICE_NAME              service name in traces (default: kickstart)
#   OTEL_EXPORTER_OTLP_ENDPOINT    e.g. http://localhost:4318 (local collector)
#   OTEL_TRACES_SAMPLER            e.g. always_on, parentbased_traceidratio
#   OTEL_TRACES_SAMPLER_ARG        sampling ratio (0.0 - 1.0)
#
# Full setup guide: docs/OBSERVABILITY.md
unless Rails.env.test?
  # Keep development quiet (no connection-refused noise) unless an OTLP
  # endpoint is explicitly configured. Production always exports.
  if ENV["OTEL_EXPORTER_OTLP_ENDPOINT"].blank? && !Rails.env.production?
    ENV["OTEL_TRACES_EXPORTER"] ||= "none"
  end

  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV.fetch("OTEL_SERVICE_NAME", "kickstart")
    c.service_version = ENV["APP_VERSION"] if ENV["APP_VERSION"].present?
    c.use_all
  end
end
