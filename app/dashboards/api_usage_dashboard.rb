# frozen_string_literal: true

require "administrate/custom_dashboard"

# Only here so Administrate lists the API usage page in its navigation
class ApiUsageDashboard < Administrate::CustomDashboard
  resource "ApiUsage"
end
