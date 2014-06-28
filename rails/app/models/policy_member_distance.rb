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
end
