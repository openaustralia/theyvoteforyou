class RenameDivisionIdColumn < ActiveRecord::Migration
  def change
    rename_column :divisions, :division_id, :id
  end
end
