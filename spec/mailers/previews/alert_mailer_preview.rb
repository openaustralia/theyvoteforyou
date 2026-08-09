# frozen_string_literal: true

# Preview for http://localhost:3088/rails/mailers (only, not used in specs)
class AlertMailerPreview < ActionMailer::Preview
  # Needs a Policy with a real PaperTrail::Version and a User: run `bin/rails db:seed` if it errors.
  def policy_updated
    AlertMailer.policy_updated(Policy.first, Policy.first.versions.last, User.first)
  end
end
