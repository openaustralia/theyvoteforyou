# frozen_string_literal: true

class RenamePwVoteSortorderTable < ActiveRecord::Migration
  def change
    rename_table :pw_vote_sortorder, :vote_sortorders
  end
end
