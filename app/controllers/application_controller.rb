class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_filter :store_location

  def electorate_param
    if params[:mpc]
      if params[:mpc][/Київ$/]
        # HACK: Hardcode constituency that contains a "."
        "м. Київ"
      else
        params[:mpc].gsub("_", " ")
      end
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :name
    devise_parameter_sanitizer.for(:account_update) << :name
  end

  private

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ /\/users/
  end

  def after_sign_in_path_for(resource)
    path = stored_location_for(resource) || session[:previous_url]
    path.nil? || path == root_path ? user_welcome_path : path
  end

  def after_sign_out_path_for(resource)
    request.referer ? URI.parse(request.referer).path : root_path
  end

  def set_locale
    FastGettext.reload! if Rails.env.development?
    I18n.locale = params[:locale] || I18n.default_locale
  end
end
