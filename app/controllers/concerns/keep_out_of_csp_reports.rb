# frozen_string_literal: true

# For pages whose address holds a secret token. A CSP violation report includes the address of the page, so these pages
# don't ask browsers to send reports to Sentry.
module KeepOutOfCspReports
  extend ActiveSupport::Concern

  included do
    content_security_policy { |policy| policy.directives.delete("report-uri") }
  end
end
