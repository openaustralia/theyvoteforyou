class MemberDistance < ActiveRecord::Base
  self.table_name = "pw_cache_realreal_distance"

  def agreement_percentage
    (1 - distance_a) * 100
  end

  def agreement_percentage_without_abstentions
    (1 - distance_b) * 100
  end
end
