# frozen_string_literal: true

# Devise's mailer, tagging each email with its kind. See MailKind.
class DeviseMailer < Devise::Mailer
  KINDS = {
    confirmation_instructions: MailKind::CONFIRMATION,
    reset_password_instructions: MailKind::PASSWORD
  }.freeze

  protected

  def headers_for(action, opts)
    super.merge(MailKind::HEADER => KINDS.fetch(action, MailKind::NOTICE))
  end
end
