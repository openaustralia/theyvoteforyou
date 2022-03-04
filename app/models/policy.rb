# frozen_string_literal: true

class Policy < ApplicationRecord
  searchkick index_name: "tvfy_policies_#{Settings.stage}" if Settings.elasticsearch
  # Using proc form of meta so that policy_id is set on create as well
  # See https://github.com/airblade/paper_trail/issues/185#issuecomment-11781496 for more details
  has_paper_trail meta: { policy_id: proc { |policy| policy.id } }
  has_many :policy_divisions, dependent: :destroy
  has_many :divisions, through: :policy_divisions
  has_many :policy_person_distances, dependent: :destroy
  has_many :divisions, through: :policy_divisions
  has_many :watches, as: :watchable, dependent: :destroy, inverse_of: :watchable
  belongs_to :user

  validates :name, :description, :private, presence: true
  validates :name, uniqueness: { case_sensitive: false }, length: { maximum: 100 }

  # TODO: Remove "legacy Dream MP"
  enum private: { :published => 0, "legacy Dream MP" => 1, :provisional => 2 }
  # TODO: Rename field in schema
  alias_attribute :status, :private

  def name_with_for
    "for #{name}"
  end

  def vote_for_division(division)
    policy_division = division.policy_divisions.find_by(policy: self)
    policy_division&.vote
  end

  def unedited_motions_count
    divisions.unedited.count
  end

  def most_recent_version
    PaperTrail::Version.order(created_at: :desc).find_by(policy_id: id)
  end

  def last_edited_at
    most_recent_version ? most_recent_version.created_at : updated_at
  end

  def last_edited_by
    User.find(most_recent_version.whodunnit)
  end

  def self.search_with_sql_fallback(query)
    if Settings.elasticsearch
      search(query)
    else
      where("LOWER(convert(name using utf8)) LIKE :query " \
            "OR LOWER(convert(description using utf8)) LIKE :query", query: "%#{query}%")
    end
  end

  def self.update_all!
    all.find_each(&:calculate_person_distances!)
  end

  def calculate_person_distances!
    policy_person_distances.delete_all

    # Step through all the divisions related to this policy
    policy_divisions.each do |policy_division|
      # Step through all members that could have voted in this division
      Member.current_on(policy_division.date).where(house: policy_division.house).find_each do |member|
        member_vote = member.votes.find_by(division: policy_division.division)

        attribute = if member_vote.nil?
                      policy_division.strong_vote? ? :nvotesabsentstrong : :nvotesabsent
                    elsif member_vote.vote == PolicyDivision.vote_without_strong(policy_division.vote)
                      policy_division.strong_vote? ? :nvotessamestrong : :nvotessame
                    else
                      policy_division.strong_vote? ? :nvotesdifferstrong : :nvotesdiffer
                    end

        ppd = PolicyPersonDistance.find_or_create_by(person_id: member.person_id, policy_id: id)
        # TODO: Do all of this counting in memory rather than overloading the database with it
        # rubocop:disable Rails/SkipsModelValidations
        ppd.increment!(attribute)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    policy_person_distances.reload.each do |pmd|
      pmd.update!(distance_a: pmd.distance_object.distance)
    end
  end

  def alert_watches(version)
    AlertWatchesJob.perform_later(self, version)
  end
end
