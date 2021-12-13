# frozen_string_literal: true

class PolicyDivision < ApplicationRecord
  # Using proc form of meta so that associated IDs are set on create as well
  # See https://github.com/airblade/paper_trail/issues/185#issuecomment-11781496 for more details
  has_paper_trail meta: { policy_id: proc { |pd| pd.policy_id }, division_id: proc { |pd| pd.division_id } }
  belongs_to :policy
  belongs_to :division
  validates :policy, :division, presence: true
  validates :vote, inclusion: { in: %w[aye3 aye no no3] }
  after_save    :calculate_policy_person_distances, :alert_policy_watches
  after_destroy :calculate_policy_person_distances, :alert_policy_watches

  delegate :name, :house, :house_name, :date, :number, to: :division

  def self.vote_without_strong(vote)
    case vote
    when "aye3"
      "aye"
    when "no3"
      "no"
    else
      vote
    end
  end

  def strong_vote?
    vote == "aye3" || vote == "no3"
  end

  private

  def calculate_policy_person_distances
    policy.delay.calculate_person_distances!
  end

  def alert_policy_watches
    policy.alert_watches(versions.last)
  end
end
