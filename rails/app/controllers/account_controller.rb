class AccountController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  def settings
    redirect_to params[:r] if @current_user && params[:r]
    if params[:submit] == 'Login to Public Whip'
      if !authenticate_user(params[:user_name], params[:password])
        @login_failed = true
        render :login
      else
        redirect_to params[:r] if params[:r]
      end
    elsif !@current_user
      render :login
    end
  end

  def logout
    # TODO: Remove - this is just here to match the PHP app
    params[:r] = "" if params[:r].nil?

    logout_user
    redirect_to params[:r] unless params[:r].blank?
  end
end
