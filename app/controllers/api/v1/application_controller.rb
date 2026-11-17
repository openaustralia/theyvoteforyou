# frozen_string_literal: true

module Api
  module V1
    class ApplicationController < ::ApplicationController
      before_action :require_key
      after_action :log_api_request

      private

      def require_key
        # A missing key, or one sent as key[]= or key[x]=, mustn't reach find_by as nil, an array or a hash
        @api_user = User.find_by(api_key: params[:key]) if params[:key].is_a?(String)
        return if @api_user

        error = "You need a valid api key. Sign up for an account on #{Rails.configuration.project_name} to get one."
        render json: { error: error }, status: :unauthorized
      end

      # The response is already rendered, so a failure here (e.g. a deadlock) is reported rather than turning it
      # into an error. Each is separate, so one failing doesn't skip the other.
      def log_api_request
        report_failure { ApiStatistic.log(request, user: @api_user) }
        report_failure { DailyApiUsage.increment(user: @api_user) }
        report_failure { LogApiCallJob.log(request, user: @api_user) }
      end

      def report_failure
        yield
      rescue StandardError => e
        Sentry.capture_exception(e)
      end
    end
  end
end
