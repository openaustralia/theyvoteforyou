# frozen_string_literal: true

class RemoveDivisionDateNumberHouseFromWikiMotions < ActiveRecord::Migration
  def change
    remove_column :wiki_motions, :division_date, :date, null: false
    remove_column :wiki_motions, :division_number, :integer, null: false
    remove_column :wiki_motions, :house, :string, limit: 8, null: false
  end
end
