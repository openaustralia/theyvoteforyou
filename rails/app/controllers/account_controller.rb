class AccountController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  def settings
    if params[:submit] == 'Login to Public Whip'
      if (user = User.find_by_user_name params[:username]) && user.password == Digest::MD5.hexdigest(params[:password])
        # log in and render settings page
      else
        @login_failed = true
      end
    end
    render :login
  end
end
