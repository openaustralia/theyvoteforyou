# frozen_string_literal: true

class PasswordsController < Devise::PasswordsController
  # Devise sends a signed-in person away from the password reset pages. The suppression notice is shown only to
  # signed-in people and offers a password reset as a way to resume their emails, so it has to work for them.
  skip_before_action :require_no_authentication
end
