# frozen_string_literal: true

class AddDivisionIdToPolicyDivisions < ActiveRecord::Migration
  def change
    add_column :policy_divisions, :division_id, :integer
    PolicyDivision.reset_column_information
    PolicyDivision.all.find_each do |pd|
      division = Division.find_by!(date: pd.read_attribute(:division_date), number: pd.read_attribute(:division_number), house: pd.read_attribute(:house))
      pd.update!(division_id: division.id)
    end
  end
end
