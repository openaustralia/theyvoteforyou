# frozen_string_literal: true

# What an outgoing email is for. Each mailer action sets its kind in the X-Postal-Tag header, which Postal repeats in its
# webhook events, so the kind is never guessed later. The tag holds only the kind, never an address or an id.
module MailKind
  HEADER = "X-Postal-Tag"

  ALERT = "alert"
  CONFIRMATION = "confirmation"
  PASSWORD = "password"
  NOTICE = "notice"
end
