# frozen_string_literal: true

module Admin
  # The busiest API keys over the last 1, 7 or 30 days, as on Planning Alerts' admin API usage page
  class ApiUsagesController < Admin::ApplicationController
    PERIODS = [30, 7, 1].freeze

    def index
      @period = PERIODS.include?(params[:period].to_i) ? params[:period].to_i : PERIODS.first
      today = Time.current.utc.to_date
      @top_users = DailyApiUsage.top_users(from: today - (@period - 1), to: today)
      @kibana_dashboard_url = kibana_dashboard_url
    end

    private

    def kibana_dashboard_url
      dashboards = Rails.configuration.x.kibana_dashboards
      return unless dashboards[:kibana_url] && dashboards[:api_usage]

      "#{dashboards[:kibana_url]}/app/dashboards#/view/#{dashboards[:api_usage]}"
    end
  end
end
