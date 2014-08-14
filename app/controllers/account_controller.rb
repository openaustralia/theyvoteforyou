class AccountController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  before_action :authenticate_user!, only: [:settings]

  def settings
    if params[:r]
      redirect_to params[:r]
    else
      render layout: "bootstrap"
    end
  end
end
