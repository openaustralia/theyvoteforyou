# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Content Security Policy, in report-only mode: browsers report what it would block, and block nothing.
# See https://github.com/openaustralia/theyvoteforyou/issues/1879 for the plan to enforce it.
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# Sentry's browser SDK reports from the visitor's browser to the host named in the DSN, and so do CSP reports.
sentry_dsn = Rails.application.credentials.dig(:sentry, :dsn)
sentry_ingest_host = sentry_dsn && URI.parse(sentry_dsn).host
sentry_report_uri = sentry_dsn && Sentry::DSN.new(sentry_dsn).csp_report_uri

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.object_src :none
    policy.frame_ancestors :self
    policy.form_action :self

    # Inline scripts need the per-request nonce below. js-de.sentry-cdn.com serves the Sentry loader script.
    policy.script_src :self, "https://js-de.sentry-cdn.com"
    # 'unsafe-inline' stays until the style="" attributes are gone.
    policy.style_src :self, :unsafe_inline, "https://code.cdn.mozilla.net"
    policy.font_src :self, "https://code.cdn.mozilla.net"
    # github.com redirects contributor avatars to avatars.githubusercontent.com.
    policy.img_src :self, :data, "https://github.com", "https://avatars.githubusercontent.com"
    policy.connect_src(*[:self, sentry_ingest_host && "https://#{sentry_ingest_host}"].compact)
    # Sentry Replay runs in a worker built from a blob: URL.
    policy.worker_src :self, :blob

    policy.report_uri sentry_report_uri if sentry_report_uri
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
  config.content_security_policy_report_only = true
end
