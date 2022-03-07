class RemoveUnusedColumnsOnDivisions < ActiveRecord::Migration[6.0]
  def change
    remove_column :divisions, :valid, :boolean
    remove_column :divisions, :markdown, :boolean, default: true, null: false
    remove_column :divisions, :source_gid, :text, null: false
  end
end
