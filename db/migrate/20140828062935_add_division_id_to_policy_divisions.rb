class AddDivisionIdToPolicyDivisions < ActiveRecord::Migration
  def change
    add_column :policy_divisions, :division_id, :integer
    PolicyDivision.reset_column_information
    PolicyDivision.all.find_each do |pd|
      division = Division.find_by!(date: pd.division_date, number: pd.division_number, house: pd.house)
      pd.update!(division_id: division.id)
    end
  end
end
