# frozen_string_literal: true

class RenamePwDynWikiMotionTable < ActiveRecord::Migration
  def change
    rename_table :pw_dyn_wiki_motion, :wiki_motions
  end
end
