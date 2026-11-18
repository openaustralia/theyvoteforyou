# frozen_string_literal: true

# Preview at /rails/mailers in development (not used in specs)
class AlertMailerPreview < ActionMailer::Preview
  # Needs a Policy with a real PaperTrail::Version and a User: run `bin/rails db:seed` if it errors.
  def policy_updated
    AlertMailer.policy_updated(Policy.first, Policy.first.versions.last, User.first)
  end
end
