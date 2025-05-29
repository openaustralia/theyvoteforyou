# frozen_string_literal: true

# TODO: Should this be renamed to PolicyVote? Would that be clearer?
class PolicyDivision < ApplicationRecord
  # Using proc form of meta so that associated IDs are set on create as well
  # See https://github.com/airblade/paper_trail/issues/185#issuecomment-11781496 for more details
  has_paper_trail meta: { policy_id: proc(&:policy_id), division_id: proc(&:division_id) }
  belongs_to :policy
  belongs_to :division
  validates :vote, inclusion: { in: %w[aye3 aye no no3] }
  after_destroy :calculate_policy_person_distances, :alert_policy_watches
  after_save    :calculate_policy_person_distances, :alert_policy_watches

  delegate :name, :house, :house_name, :date, :number, to: :division

  scope :published, -> { joins(:policy).merge(Policy.published) }

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
    %w[aye3 no3].include?(vote)
  end

  private

  # Callbacks can make testing models and reasoning about models confusing IMHO
  # So, better I think to move to controller where the relevant action takes place
  # or if that action is used in several places and/or is complicated move it to a
  # service class.
  # TODO: Move callback out of model
  def calculate_policy_person_distances
    CalculatePolicyPersonDistancesJob.perform_later(policy)
  end

  def alert_policy_watches
    policy.alert_watches(versions.last)
  end
end
