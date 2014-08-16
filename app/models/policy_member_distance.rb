class PolicyMemberDistance < ActiveRecord::Base
  self.table_name = "pw_cache_dreamreal_distance"

  attr_defaults nvotessame: 0.0,
                nvotessamestrong: 0.0,
                nvotesdiffer: 0.0,
                nvotesdifferstrong: 0.0,
                nvotesabsent: 0.0,
                nvotesabsentstrong: 0.0,
                distance_a: 0.0,
                distance_b: 0.0

  belongs_to :policy, foreign_key: :dream_id

  # TODO replace with association when we can
  def person_object
    Person.new(id: person)
  end

  # TODO: Rename these attributes.
  # These are disabled because we can't use these yet thanks to the missing primary key ass hattery below
  # alias_attribute :distance_a, :distance
  # alias_attribute :distance_b, :distance_without_abstentions

  # Use update_all because we don't yet have a primary key on this model
  # TODO: Add a primary key and get rid of this function
  def increment!(attribute, by = 1)
    increment(attribute, by)
    PolicyMemberDistance.where(dream_id: policy.id, person: person).update_all(attribute => read_attribute(attribute))
  end

  # Use update_all because we don't yet have a primary key on this model
  # TODO: Add a primary key and get rid of this function
  def update!(attributes)
    PolicyMemberDistance.where(dream_id: policy.id, person: person).update_all(attributes)
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
