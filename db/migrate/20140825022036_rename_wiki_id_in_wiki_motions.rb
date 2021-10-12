# frozen_string_literal: true

class RenameWikiIdInWikiMotions < ActiveRecord::Migration
  def change
    rename_column :wiki_motions, :wiki_id, :id
  end
end
