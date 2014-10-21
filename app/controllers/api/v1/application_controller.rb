class Api::V1::ApplicationController < ApplicationController
  before_action :require_key
  after_action :log_api_request

  private

  def require_key
    # Not every user has the api_key set. So explicitly handle the nil case
    user = User.find_by(api_key: params[:key]) if params[:key]
    if user.nil?
      render json: {error: "You need a valid api key. Sign up for an account on #{Settings.project_name} to get one."}, status: :unauthorized
    end
  end

  def log_api_request
    ApiStatistic.log(request)
  end
end
