# frozen_string_literal: true

# An email address that alert emails are no longer sent to, because of a hard bounce. Design and terms:
# https://github.com/openaustralia/theyvoteforyou/issues/1795
#
# It belongs to the address, not to a user, so the same rule applies if the address changes hands or the person changes
# their address. Lifting keeps the row, so there is a history of why updates stopped. A later hard bounce makes a fresh
# active suppression.
class EmailSuppression < ApplicationRecord
  REPLY_EXCERPT_LENGTH = 255

  # Every read and write of an address goes through this, including where(address: ...), so Alice@Example.org and
  # alice@example.org are one address. https://api.rubyonrails.org/classes/ActiveRecord/Normalization/ClassMethods.html
  normalizes :address, with: ->(address) { EmailSuppression.bare_address(address) }

  enum :reason, { hard_bounce: "hard_bounce", imported_from_postal: "imported_from_postal", staff: "staff" },
       validate: true

  validates :address, :suppressed_at, presence: true

  scope :active, -> { where(lifted_at: nil) }

  def self.bare_address(address)
    Mail::Address.new(address.to_s).address.to_s.strip.downcase
  rescue Mail::Field::ParseError
    address.to_s.strip.downcase
  end

  def self.suppressed?(address)
    active.exists?(address: address)
  end

  # Does nothing if the address already has an active suppression, so repeated or duplicate Postal events are harmless.
  # Inserts first and relies on the unique index on active_address, so two events handled at once can't both succeed.
  def self.suppress!(address, reason:, postal_event: nil, reply: nil, at: Time.current)
    create!(address: address, reason: reason, postal_event: postal_event,
            reply_excerpt: reply&.truncate(REPLY_EXCERPT_LENGTH), suppressed_at: at)
  rescue ActiveRecord::RecordNotUnique
    active.find_by!(address: address)
  end

  # Returns how many active suppressions were lifted (0 or 1).
  def self.lift!(address)
    active.where(address: address).update_all(lifted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
