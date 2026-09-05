# frozen_string_literal: true

# The canonical OAF Sentry configuration - the same settings are carried by
# each collection's repo. The convention lives in the infrastructure repo's
# docs/monitoring.md; change it there first, then update every copy.

# Matches most email addresses. Used to scrub personal information from
# breadcrumbs (e.g. log lines that mention a person's email address) in line
# with the Australian Privacy Principles.
email_pattern = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/

scrub_value = lambda do |value|
  case value
  when String then value.gsub(email_pattern, "[FILTERED]")
  when Hash then value.transform_values { |v| scrub_value.call(v) }
  when Array then value.map { |v| scrub_value.call(v) }
  else value
  end
end

scrub_breadcrumbs = lambda do |event, _hint|
  event.breadcrumbs&.buffer&.each do |crumb|
    crumb.message = scrub_value.call(crumb.message) if crumb.message
    crumb.data = scrub_value.call(crumb.data) if crumb.data
  end
  event
end

Sentry.init do |config|
  # With no DSN (local development and test) the SDK is disabled - that is
  # the off switch
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  # The Sentry environment is always the Capistrano stage name. Rails.env
  # already equals the stage here (passenger_app_env per stage), so the ENV
  # override is a formality for consistency with the other collections.
  config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  # Release is auto-detected from Capistrano's REVISION file (full git SHA)
  config.traces_sample_rate = 0.1
  # If the infrastructure repo's otel-sidecar collector lands, traces can route through it
  # via sentry-opentelemetry + config.otlp.* instead of traces_sample_rate
  # Include user IPs and request data (cookies, headers, query strings) with
  # events. Secrets that travel in query strings (API keys, Devise tokens) are
  # scrubbed via Rails' filter_parameters - see filter_parameter_logging.rb -
  # and emails are scrubbed from breadcrumbs above
  config.send_default_pii = true
  config.before_send = scrub_breadcrumbs
  config.before_send_transaction = scrub_breadcrumbs
  # Send Rails logs to Sentry as structured logs
  config.enable_logs = true
  config.enabled_patches << :logger
  # Profile the same fraction of transactions that we trace, using vernier
  config.profiles_sample_rate = 0.1
  config.profiler_class = Sentry::Vernier::Profiler
end
