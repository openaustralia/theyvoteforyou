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
      user = User.find_by_user_name(params[:change_user_name])
      if params[:new_password1] != params[:new_password2]
        flash[:error] = 'New passwords must match.'
      elsif user.nil? || user.password != Digest::MD5.hexdigest(params[:old_password].downcase)
        flash[:error] = 'User not found or bad password.'
      else
        user.change_password params[:new_password1]
        user.save
        flash[:notice] = 'Password changed.'
        @password_changed = true
      end
    end
  end

  # FIXME: Move this to the division controller
  def edit_division
    params[:house] ||= 'representatives'
    @division = Division.in_australian_house(params[:house]).find_by!(division_date: params[:date], division_number: params[:number])
  end
end
