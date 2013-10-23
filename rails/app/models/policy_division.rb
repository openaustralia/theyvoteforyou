class PolicyDivision < ActiveRecord::Base
  self.table_name = 'pw_dyn_dreamvote'
  belongs_to :policy

  def division
    divisions = Division.where(division_date: division_date,
                               division_number: division_number,
                               house: house)
    raise 'Multiple divisions found' if divisions.size > 1
    divisions.first
  end
end
