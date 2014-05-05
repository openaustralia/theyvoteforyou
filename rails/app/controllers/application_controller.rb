class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :user_signed_in?, :current_user

  def authenticate_user(user_name, password)
    if (user = User.find_by_user_name params[:user_name]) && user.password == Digest::MD5.hexdigest(params[:password].downcase)
      session[:user_name] = user.user_name
    end
  end

  def logout_user
    session[:user_name], @current_user = nil, nil
  end

  def current_user
    @current_user ||= User.find_by_user_name session[:user_name]
  end

  def user_signed_in?
    !!current_user
  end
end
