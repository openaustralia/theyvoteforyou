class MemberDistance < ActiveRecord::Base
  self.table_name = "pw_cache_realreal_distance"
  belongs_to :member, foreign_key: :mp_id1

  # TODO: Can we do this as an association?
  def member2
    Member.find mp_id2
  end

  def agreement_percentage
    (1 - distance_a) * 100
  end

  def agreement_percentage_without_abstentions
    (1 - distance_b) * 100
  end
end
