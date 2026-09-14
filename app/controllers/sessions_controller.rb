# frozen_string_literal: true

# Exists only to hang the ALTCHA proof-of-work check off the log in form.
#
# The check is a plain before_action rather than a prepended one so that Devise's own
# require_no_authentication still runs first: somebody already signed in should be bounced by
# Devise rather than asked to solve a puzzle.
class SessionsController < Devise::SessionsController
  include AltchaProtected

  before_action :check_altcha, only: :create
end
