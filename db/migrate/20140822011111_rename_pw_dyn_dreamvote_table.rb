# frozen_string_literal: true

class RenamePwDynDreamvoteTable < ActiveRecord::Migration
  def change
    rename_table :pw_dyn_dreamvote, :policy_divisions
  end
end
