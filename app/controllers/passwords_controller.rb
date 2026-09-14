# frozen_string_literal: true

# Exists only to hang the ALTCHA proof-of-work check off the password reset request form, which
# is the form where an unchecked bot costs us most: every submission sends an email under our
# name, so a flood damages the deliverability of every OAF project's mail.
class PasswordsController < Devise::PasswordsController
  include AltchaProtected

  before_action :check_altcha, only: :create
end
