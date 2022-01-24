class DropEditDateInWikiMotions < ActiveRecord::Migration[5.0]
  def change
    remove_column :wiki_motions, :edit_date, :datetime
  end
end
