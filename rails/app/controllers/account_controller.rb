class AccountController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  def settings
    if params[:submit] == 'Login to Public Whip'
      if !authenticate_user(params[:user_name], params[:password])
        @login_failed = true
        render :login
      end
    elsif !@current_user
      render :login
    end
  end
end
