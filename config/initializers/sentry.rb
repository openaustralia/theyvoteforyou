# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.environment = Rails.env
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  # Release is auto-detected from Capistrano's REVISION file (full git SHA)
  config.traces_sample_rate = 0.1
  # If the infrastructure repo's otel-sidecar collector lands, traces can route through it
  # via sentry-opentelemetry + config.otlp.* instead of traces_sample_rate
  # Include user IPs and request data (cookies, headers, query strings) with
  # events. Secrets that travel in query strings (API keys, Devise tokens) are
  # scrubbed via Rails' filter_parameters - see filter_parameter_logging.rb
  config.send_default_pii = true
  # Send Rails logs to Sentry as structured logs
  config.enable_logs = true
  config.enabled_patches << :logger
  # Profile the same fraction of transactions that we trace, using vernier
  config.profiles_sample_rate = 0.1
  config.profiler_class = Sentry::Vernier::Profiler
end
