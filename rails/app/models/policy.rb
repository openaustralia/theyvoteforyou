class Policy < ActiveRecord::Base
  self.table_name = 'pw_dyn_dreammp'

  has_many :policy_divisions, foreign_key: :dream_id
  has_one :policy_info, foreign_key: :dream_id

  delegate :votes_count, :edited_motions_count, to: :policy_info

  # HACK: Not using an association due to the fact that policy_divisions doesn't include a division_id!
  def divisions
    policy_divisions.collect { |pd| pd.division }
  end

  def unedited_motions
    votes_count - edited_motions_count
  end
end
