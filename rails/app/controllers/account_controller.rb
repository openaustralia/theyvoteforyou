class AccountController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  def settings
    if params[:submit] == 'Login to Public Whip'
      if (user = User.find_by_user_name params[:user_name]) && user.password == Digest::MD5.hexdigest(params[:password])
        session[:user_name] = user.user_name
      else
        @login_failed = true
        render :login
      end
    else
      render :login
    end
  end
end
