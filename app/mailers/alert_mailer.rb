# frozen_string_literal: true

class AlertMailer < ApplicationMailer
  default from: "#{Settings.project_name} <#{Settings.contact_email}>"
  layout "email"
  helper PoliciesHelper, DivisionsHelper, PathHelper

  def policy_updated(policy, version, user)
    @policy = policy
    @version = version
    @user = user

    mail to: user.email, subject: render_to_string(partial: "policy_updated_subject").strip
  end
end
