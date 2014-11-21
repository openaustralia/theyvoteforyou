class AlertMailer < ActionMailer::Base
  default from: "from@example.com"
  helper PoliciesHelper

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
