class PolicyDivision < ActiveRecord::Base
  self.table_name = 'pw_dyn_dreamvote'
  belongs_to :policy, foreign_key: :dream_id

  alias_attribute :date, :division_date
  alias_attribute :number, :division_number

  delegate :name, :australian_house, :australian_house_name, to: :division

  def division
    divisions = Division.where(division_date: division_date,
                               division_number: division_number,
                               house: house)
    raise 'Multiple divisions found' if divisions.size > 1
    divisions.first
  end

  def strong_vote?
    vote == 'aye3' || vote == 'no3'
  end
end
