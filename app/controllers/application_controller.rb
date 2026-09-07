# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # For reason for "prepend: true" see
  # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#protect-from-forgery-now-defaults-to-prepend-false
  protect_from_forgery prepend: true, with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :store_location
  before_action :set_paper_trail_whodunnit
  before_action :set_sentry_user

  include Pundit::Authorization

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  private

  # Attach the signed-in user to Sentry events so errors show who was affected.
  # Sentry's Rack middleware resets the scope every request, so this can't leak
  # between requests. The id only, never email or name - look the id up in the
  # admin backend if you need to contact someone about an error (Australian
  # Privacy Principles, and the canonical configuration in the infrastructure
  # repo's docs/monitoring.md).
  def set_sentry_user
    Sentry.set_user(id: current_user.id) if user_signed_in?
  end

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ %r{/users}
  end

  def after_sign_in_path_for(resource)
    path = stored_location_for(resource) || session[:previous_url]
    path.nil? || path == root_path ? user_welcome_path : path
  end

  def after_sign_out_path_for(_resource)
    request.referer ? URI.parse(request.referer).path : root_path
  end
end
