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
    Distance.new(nvotessame, nvotessamestrong, nvotesdiffer, nvotesdifferstrong, nvotesabsent, nvotesabsentstrong)
  end

  def votes_same_strong_points
    distance_object.votes_points(:samestrong)
  end

  def possible_same_strong_points
    distance_object.possible_votes_points(:samestrong)
  end

  def votes_differ_strong_points
    distance_object.votes_points(:differstrong)
  end

  def possible_differ_strong_points
    distance_object.possible_votes_points(:differstrong)
  end

  def votes_absent_strong_points
    distance_object.votes_points(:absentstrong)
  end

  def possible_absent_strong_points
    distance_object.possible_votes_points(:absentstrong)
  end

  def votes_same_points
    distance_object.votes_points(:same)
  end

  def possible_same_points
    distance_object.possible_votes_points(:same)
  end

  def votes_differ_points
    distance_object.votes_points(:differ)
  end

  def possible_differ_points
    distance_object.possible_votes_points(:differ)
  end

  def votes_absent_points
    distance_object.votes_points(:absent)
  end

  def possible_absent_points
    distance_object.possible_votes_points(:absent)
  end

  delegate :total_points, to: :distance_object

  delegate :possible_total_points, to: :distance_object

  def agreement_fraction
    1 - distance_a
  end

  def number_of_votes
    nvotessame + nvotessamestrong + nvotesdiffer + nvotesdifferstrong
  end
end
