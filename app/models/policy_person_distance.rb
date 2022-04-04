# frozen_string_literal: true

class PolicyPersonDistance < ApplicationRecord
  # TODO: Remove distance_b from database schema
  attr_defaults nvotessame: 0.0,
                nvotessamestrong: 0.0,
                nvotesdiffer: 0.0,
                nvotesdifferstrong: 0.0,
                nvotesabsent: 0.0,
                nvotesabsentstrong: 0.0,
                distance_a: 0.0

  belongs_to :policy
  belongs_to :person

  scope :published, -> { joins(:policy).merge(Policy.published) }

  # People who are currently in parliament
  scope :currently_in_parliament, -> { joins(:person).merge(Person.current) }

  def voted?
    nvotessame.positive? || nvotessamestrong.positive? || nvotesdiffer.positive? || nvotesdifferstrong.positive?
  end

  def distance_object
    Distance.new(same: nvotessame, samestrong: nvotessamestrong, differ: nvotesdiffer, differstrong: nvotesdifferstrong, absent: nvotesabsent, absentstrong: nvotesabsentstrong)
  end

  delegate :total_points, :possible_total_points, :votes_points, :possible_votes_points, to: :distance_object

  def agreement_fraction
    1 - distance_a
  end

  def number_of_votes
    nvotessame + nvotessamestrong + nvotesdiffer + nvotesdifferstrong
  end

  def number_of_votes_strong
    nvotessamestrong + nvotesdifferstrong
  end

  def self.category_range_mapping
    {
      for3: 0.95..1.00,
      for2: 0.85..0.95,
      for1: 0.60..0.85,
      mixture: 0.40..0.60,
      against1: 0.15..0.40,
      against2: 0.05..0.15,
      against3: 0.00..0.05
    }
  end

  def self.all_categories(reverse: false)
    list = %i[
      for3
      for2
      for1
      mixture
      against1
      against2
      against3
    ]
    list.reverse! if reverse
    # Always put :not_enough at the end irrespective of whether we're reversing the list
    list + [:not_enough]
  end

  def category
    # If a person has voted on a policy less than three times and none of the votes were "strong" then we really
    # can't make a clear statement of their stance on a policy. So we say "we don't have enough information"
    return :not_enough if number_of_votes < 2 && number_of_votes_strong.zero?

    PolicyPersonDistance.category_range_mapping.find do |_category, range|
      range.include?(agreement_fraction)
    end.first
  end

  def update_distance!
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

    update(
      nvotesabsentstrong: absentstrong,
      nvotesabsent: absent,
      nvotessamestrong: samestrong,
      nvotessame: same,
      nvotesdifferstrong: differstrong,
      nvotesdiffer: differ,
      distance_a: Distance.new(same: same, samestrong: samestrong, differ: differ, differstrong: differstrong, absent: absent, absentstrong: absentstrong).distance
    )
  end
end
