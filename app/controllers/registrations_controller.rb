# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  include AltchaProtected

  # Two independent spam controls, kept deliberately. The honeypot costs nothing and still works
  # with JavaScript turned off, so it is the only thing standing whenever the ALTCHA flags are
  # off. It also catches a different sort of bot: naive form fillers that populate every field,
  # rather than ones that render and run scripts but will not spend CPU.
  invisible_captcha only: :create, honeypot: :title, scope: :user
  before_action :check_altcha, only: :create

  protected

  def after_inactive_sign_up_path_for(_resource)
    user_confirm_path
  end

  private

  # Keep the username as well as the email. build_resource does not save.
  def altcha_redisplay_resource
    build_resource(sign_up_params)
  end
end
