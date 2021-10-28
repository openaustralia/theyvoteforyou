# frozen_string_literal: true

class RenameDivisionDateNumberNameInDivisions < ActiveRecord::Migration
  def change
    rename_column :divisions, :division_date, :date
    rename_column :divisions, :division_number, :number
    rename_column :divisions, :division_name, :name
  end
end
