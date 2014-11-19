class AlertMailer < ActionMailer::Base
  default from: "from@example.com"
  helper PoliciesHelper

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.alert_mailer.policy_updated.subject
  #
  def policy_updated(version)
    @version = version

    mail to: "to@example.org"
  end
end
