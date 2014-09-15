class AccountController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  before_action :authenticate_user!, only: [:settings]

  def settings
    user = User.find(params[:id])
    # For the time being only allowed to look at your own profile
    if user != current_user
      render text: "unauthorized", status: :unauthorized
    end
  end
end
