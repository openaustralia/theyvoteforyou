# frozen_string_literal: true

# For pages whose address holds a secret token. A CSP violation report includes the address of the page, so these pages
# don't ask browsers to send reports to Sentry. A report from the next page also includes its referrer, so these pages
# send no referrer either.
module KeepOutOfCspReports
  extend ActiveSupport::Concern

  included do
    content_security_policy { |policy| policy.directives.delete("report-uri") }
    before_action { response.set_header("Referrer-Policy", "no-referrer") }
  end
end
