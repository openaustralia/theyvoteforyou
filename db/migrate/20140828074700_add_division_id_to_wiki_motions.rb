# frozen_string_literal: true

class AddDivisionIdToWikiMotions < ActiveRecord::Migration
  def change
    add_column :wiki_motions, :division_id, :integer
    add_index :wiki_motions, :division_id
    WikiMotion.reset_column_information
    WikiMotion.all.find_each do |w|
      division = Division.find_by!(date: w.division_date, number: w.division_number, house: w.house)
      # I don't want callbacks called
      w.update_attribute(:division_id, division.id)
    end
  end
end
