class AlertMailer < ActionMailer::Base
  default from: "#{Settings.project_name} <#{Settings.contact_email}>"
  layout 'email'
  helper PoliciesHelper, DivisionsHelper, PathHelper

  def policy_updated(version, user)
    @version = version

    mail to: user.email, subject: render_to_string(partial: 'policy_updated_subject')
  end
end
