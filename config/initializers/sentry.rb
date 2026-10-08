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
  event.breadcrumbs&.each do |crumb|
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
  # The SDK always filters keys like token and password; sentry-rails adds
  # Rails' filter_parameters.
  config.data_collection.tap do |data|
    data.user_info = true
    data.cookies = true
    data.http_headers.request = true
    data.http_headers.response = true
    data.url_query_params = true
    data.http_bodies = %i[incoming_request outgoing_request incoming_response outgoing_response]
    data.database_query_data = true
    data.queues = true
    data.graphql.document = true
    data.graphql.variables = true
    data.stack_frame_variables = false
    data.frame_context_lines = 3
  end
  config.before_send = scrub_breadcrumbs
  config.before_send_transaction = scrub_breadcrumbs
  # Rails logs arrive via sentry-rails' structured logging, on by default
  # since 7.0; the logger patch additionally forwards non-Rails stdlib
  # logging (e.g. the delayed_job worker's)
  config.enabled_patches << :logger
  # Profile the same fraction of transactions that we trace, using vernier
  config.profiles_sample_rate = 0.1
  config.profiler_class = Sentry::Vernier::Profiler
end
