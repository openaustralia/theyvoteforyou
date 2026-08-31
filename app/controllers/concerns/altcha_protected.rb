# frozen_string_literal: true

# Runs the ALTCHA proof-of-work check on an anonymous Devise form. Include it in a Devise
# controller and add `before_action :check_altcha, only: :create`.
#
# Two flags, and the AND between them is the point:
#
#   :altcha          renders the widget, checks answers, logs the outcome, blocks nothing
#   :altcha_enforce  turns a failed or missing answer into a rejection
#
# :altcha_enforce means nothing unless :altcha is also on, so switching :altcha off is a complete
# rollback on its own. The other way round would leave all four sign in and sign up forms
# rejecting everyone with no widget on the page to satisfy them.
#
# Use the on/off gate only. Percentage gates do not work here: rendering the form and posting it
# are two different requests, so a visitor can be given a form with no widget and then met with
# enforcement on submit. Anonymous visitors have no Flipper actor to key a percentage on either.
module AltchaProtected
  extend ActiveSupport::Concern

  included do
    helper_method :altcha_widget?, :altcha_challenge_json
  end

  private

  def altcha_widget?
    Flipper.enabled?(:altcha)
  end

  def altcha_enforced?
    altcha_widget? && Flipper.enabled?(:altcha_enforce)
  end

  # Memoised so that a form rendered twice in one request cannot embed two different challenges.
  def altcha_challenge_json
    @altcha_challenge_json ||= AltchaChallenge.issue(scope: controller_name).to_json
  end

  def check_altcha
    return unless altcha_widget?

    result = AltchaChallenge.verify(params[:altcha], scope: controller_name)
    Rails.logger.info("[altcha] form=#{controller_name} outcome=#{result.outcome} enforced=#{altcha_enforced?}")
    return if result.verified? || !altcha_enforced?

    reject_altcha
  end

  # Rendering from a before_action halts the chain, which is what stops the Devise action running.
  # Re-rendering rather than redirecting keeps what they typed, and the re-render embeds a fresh
  # challenge, so somebody rejected for an expired or already spent one succeeds on the retry.
  def reject_altcha
    self.resource = altcha_redisplay_resource
    flash.now[:alert] = altcha_rejection_message
    render :new, status: :unprocessable_content
  end

  # Enough of a resource to redraw the form with what they typed. Three of the four forms only
  # have an email worth keeping, and a password field is never redrawn by Rails anyway.
  def altcha_redisplay_resource
    resource_class.new(email: params.dig(resource_name, :email))
  end

  def altcha_rejection_message
    "We couldn't finish the automated check that keeps spam off this form. It needs JavaScript " \
      "turned on in your browser. Wait for the check to finish, then try again. If you're stuck, " \
      "email #{Rails.configuration.contact_email} and we'll sort it out."
  end
end
