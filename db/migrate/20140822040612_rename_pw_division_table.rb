class RenamePwDivisionTable < ActiveRecord::Migration
  def change
    rename_table :pw_division, :divisions
  end
end
