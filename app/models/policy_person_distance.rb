class PolicyPersonDistance < ApplicationRecord
  attr_defaults nvotessame: 0.0,
                nvotessamestrong: 0.0,
                nvotesdiffer: 0.0,
                nvotesdifferstrong: 0.0,
                nvotesabsent: 0.0,
                nvotesabsentstrong: 0.0,
                distance_a: 0.0,
                distance_b: 0.0

  belongs_to :policy
  has_one :person, foreign_key: :id, primary_key: :person_id

  scope :published, -> { joins(:policy).merge(Policy.published) }
  scope :very_strongly_for,     -> { where(distance_a: (0.00...0.05)) }
  scope :strongly_for,          -> { where(distance_a: (0.05...0.15)) }
  scope :moderately_for,        -> { where(distance_a: (0.15...0.40)) }
  scope :for_and_against,       -> { where(distance_a: (0.40...0.60)).where("(nvotessame + nvotessamestrong + nvotesdiffer + nvotesdifferstrong) > 0") }
  scope :moderately_against,    -> { where(distance_a: (0.60...0.85)) }
  scope :strongly_against,      -> { where(distance_a: (0.85...0.95)) }
  scope :very_strongly_against, -> { where(distance_a: (0.95..1.0)) }
  scope :never_voted,           -> { where(nvotessame: 0, nvotessamestrong: 0, nvotesdiffer: 0, nvotesdifferstrong: 0) }

  def voted?
    nvotessame > 0 || nvotessamestrong > 0 || nvotesdiffer > 0 || nvotesdifferstrong > 0
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

  def total_points
    distance_object.total_points
  end

  def possible_total_points
    distance_object.possible_total_points
  end

  def agreement_fraction
    1 - distance_a
  end

  def number_of_votes
    nvotessame + nvotessamestrong + nvotesdiffer + nvotesdifferstrong
  end
end
