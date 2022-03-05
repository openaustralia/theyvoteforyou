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

  def members_who_could_have_voted_on_this_policy
    member_ids = []
    divisions.each do |division|
      member_ids += division.members_who_could_have_voted.pluck(:id)
    end
    member_ids.uniq.map { |id| Member.find(id) }
  end

  def people_who_could_have_voted_on_this_policy
    members_who_could_have_voted_on_this_policy.map(&:person_id).uniq.map { |id| Person.find(id) }
  end

  def calculate_person_distances!
    people = people_who_could_have_voted_on_this_policy

    # Delete records that shouldn't be there anymore and won't be update further below
    policy_person_distances.where(PolicyPersonDistance.arel_table[:person_id].not_in(people.map(&:id))).delete_all

    # Step through all the people that could have voted on this policy
    people.each do |person|
      ppd = PolicyPersonDistance.find_or_initialize_by(person_id: person.id, policy_id: id)
      ppd.update(calculate_distance(person))
    end
  end

  def self.calculate_distance2(person, policy)
    absentstrong = 0
    absent = 0
    samestrong = 0
    same = 0
    differstrong = 0
    differ = 0

    # Step through all members for this person
    person.members.each do |member|
      # Get the votes for all the divisions in a single query
      member_votes = member.votes.where(division: policy.divisions).to_a
      # Step through all the divisions related to this policy
      policy.policy_divisions.each do |policy_division|
        next unless member.in_parliament_on_date(policy_division.date) && member.house == policy_division.house

        member_vote = member_votes.find { |v| v.division_id == policy_division.division_id }

        if member_vote.nil?
          policy_division.strong_vote? ? absentstrong += 1 : absent += 1
        elsif member_vote.vote == PolicyDivision.vote_without_strong(policy_division.vote)
          policy_division.strong_vote? ? samestrong += 1 : same += 1
        else
          policy_division.strong_vote? ? differstrong += 1 : differ += 1
        end
      end
    end

    {
      nvotesabsentstrong: absentstrong,
      nvotesabsent: absent,
      nvotessamestrong: samestrong,
      nvotessame: same,
      nvotesdifferstrong: differstrong,
      nvotesdiffer: differ,
      distance_a: Distance.new(same: same, samestrong: samestrong, differ: differ, differstrong: differstrong, absent: absent, absentstrong: absentstrong).distance
    }
  end

  def calculate_distance(person)
    Policy.calculate_distance2(person, self)
  end

  def alert_watches(version)
    AlertWatchesJob.perform_later(self, version)
  end
end
