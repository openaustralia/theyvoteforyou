class Policy < ActiveRecord::Base
  self.table_name = 'pw_dyn_dreammp'

  has_many :policy_divisions, foreign_key: :dream_id

  # HACK: Not using an association due to the fact that policy_divisions doesn't include a division_id!
  def divisions
    policy_divisions.collect { |pd| pd.division }
  end
end
