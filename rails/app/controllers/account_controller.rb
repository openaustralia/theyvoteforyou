class AccountController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  def settings
    if params[:submit] == 'Login to Public Whip'
      if !authenticate_user(params[:user_name], params[:password])
        @login_failed = true
        render :login
      else
        redirect_to params[:r] if params[:r]
      end
    elsif !user_signed_in?
      render :login
    end
  end

  def logout
    # TODO: Remove - this is just here to match the PHP app
    params[:r] = "" if params[:r].nil?

    logout_user
    redirect_to params[:r] unless params[:r].blank?
  end

  def change_password
    if params[:submit] == 'Change My Password'
      if params[:new_password1] != params[:new_password2]
        flash[:error] = 'New passwords must match.'
      end
    end
  end
end
