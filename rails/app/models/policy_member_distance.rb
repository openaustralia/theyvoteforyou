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
  belongs_to :member, foreign_key: :person, primary_key: :person

  # TODO: Rename these attributes.
  # These are disabled because we can't use these yet thanks to the missing primary key ass hattery below
  # alias_attribute :distance_a, :distance
  # alias_attribute :distance_b, :distance_without_abstentions

  # Use update_all because we don't yet have a primary key on this model
  # TODO: Add a primary key and get rid of this function
  def increment!(attribute, by = 1)
    increment(attribute, by)
    PolicyMemberDistance.where(dream_id: policy.id, person: member.person).update_all(attribute => read_attribute(attribute))
  end

  # Use update_all because we don't yet have a primary key on this model
  # TODO: Add a primary key and get rid of this function
  def update!(attributes)
    PolicyMemberDistance.where(dream_id: policy.id, person: member.person).update_all(attributes)
  end

  def votes_same_strong_points
    nvotessamestrong * 50
  end

  def possible_same_strong_points
    policy ? policy.policy_divisions.select { |pd| pd.australian_house == member.australian_house && pd.strong_vote? && member.vote_on_division(pd.division) != 'absent' }.count * 50 : 0
  end

  def votes_absent_stong_points
    nvotesabsentstrong * 25
  end

  def possible_absent_stong_points
    policy ? policy.policy_divisions.select { |pd| pd.australian_house == member.australian_house && pd.strong_vote? && member.vote_on_division(pd.division) == 'absent' }.count * 25 : 0
  end

  def votes_same_points
    nvotessame * 10
  end

  def possible_same_points
    policy ? policy.policy_divisions.select { |pd| pd.australian_house == member.australian_house && !pd.strong_vote? && member.vote_on_division(pd.division) != 'absent' }.count * 10 : 0
  end

  def votes_absent_points
    nvotesabsent
  end

  def possible_absent_points
    policy ? policy.policy_divisions.select { |pd| pd.australian_house == member.australian_house && !pd.strong_vote? && member.vote_on_division(pd.division) == 'absent' }.count * 2 : 0
  end

  def total_points
    votes_same_strong_points +
    votes_absent_stong_points +
    votes_same_points +
    votes_absent_points
  end

  def possible_total_points
    possible_same_strong_points +
    possible_absent_stong_points +
    possible_same_points +
    possible_absent_points
  end
end
