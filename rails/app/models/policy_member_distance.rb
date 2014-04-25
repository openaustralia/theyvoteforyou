class PolicyMemberDistance < ActiveRecord::Base
  self.table_name = "pw_cache_dreamreal_distance"

  belongs_to :policy, foreign_key: :dream_id
  belongs_to :member, foreign_key: :person, primary_key: :person
end
