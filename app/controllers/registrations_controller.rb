class RegistrationsController < Devise::RegistrationsController
  invisible_captcha only: :create, honeypot: :title, scope: :user

  protected

  def after_inactive_sign_up_path_for(_resource)
    user_confirm_path
  end
end
