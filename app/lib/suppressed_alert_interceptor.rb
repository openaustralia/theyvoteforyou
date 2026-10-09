# frozen_string_literal: true

# The one place that decides whether an email goes to a suppressed address. Only alert mail is held back. Anything the
# person has just asked for (confirmation, password reset) is sent, because it is one email triggered by a fresh action,
# and a repeat bounce suppresses the address again at once.
#
# Registered in config/application.rb. https://guides.rubyonrails.org/action_mailer_basics.html#intercepting-and-observing-emails
class SuppressedAlertInterceptor
  def self.delivering_email(message)
    return unless message[MailKind::HEADER]&.value == MailKind::ALERT

    message.perform_deliveries = false if Array(message.to).any? { |address| EmailSuppression.suppressed?(address) }
  end
end
