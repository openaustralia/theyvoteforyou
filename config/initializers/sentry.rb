# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.environment = Rails.env
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  # Release is auto-detected from Capistrano's REVISION file (full git SHA)
  config.traces_sample_rate = 0.1
  # If the infrastructure repo's otel-sidecar collector lands, traces can route through it
  # via sentry-opentelemetry + config.otlp.* instead of traces_sample_rate
  config.send_default_pii = false
end
