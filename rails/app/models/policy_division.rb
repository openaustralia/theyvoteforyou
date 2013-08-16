class PolicyDivision < ActiveRecord::Base
  self.table_name = 'pw_dyn_dreamvote'
  belongs_to :policy

  def division
    Division.where(division_date: division_date, division_number: division_number).first
  end
end
