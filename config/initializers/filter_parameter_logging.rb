# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
#
# This filter also applies to the request data Sentry captures with events
# (send_default_pii is enabled in sentry.rb). :key is the API key query
# parameter; the Devise tokens appear in query strings of emailed links.
Rails.application.config.filter_parameters += %i[password key reset_password_token confirmation_token]
