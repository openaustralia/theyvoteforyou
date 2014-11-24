class AlertMailer < ActionMailer::Base
  default from: "#{Settings.project_name} <#{Settings.contact_email}>"
  layout 'email'
  helper PoliciesHelper, DivisionsHelper, PathHelper

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.alert_mailer.policy_updated.subject
  #
  def policy_updated(version, user)
    @version = version

    mail to: user.email
  end
end
