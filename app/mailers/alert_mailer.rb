# frozen_string_literal: true

class AlertMailer < ApplicationMailer
  default from: "#{Rails.configuration.project_name} <#{Rails.configuration.contact_email}>"
  layout "email"
  helper PoliciesHelper, DivisionsHelper, PathHelper

  def policy_updated(policy, version, user)
    @policy = policy
    @version = version
    @user = user

    mail to: user.email, subject: render_to_string(partial: "policy_updated_subject", locals: { policy: @policy }).strip
  end
end
