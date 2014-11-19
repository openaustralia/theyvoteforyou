class AlertMailer < ActionMailer::Base
  default from: "from@example.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.alert_mailer.policy_updated.subject
  #
  def policy_updated
    @greeting = "Hi"

    mail to: "to@example.org"
  end
end
