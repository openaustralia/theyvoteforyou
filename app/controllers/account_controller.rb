class AccountController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  before_action :authenticate_user!, only: [:settings]

  def settings
    redirect_to params[:r] if params[:r]
  end
end
