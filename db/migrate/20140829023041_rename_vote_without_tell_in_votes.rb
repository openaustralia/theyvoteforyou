# frozen_string_literal: true

class RenameVoteWithoutTellInVotes < ActiveRecord::Migration
  def change
    rename_column :votes, :vote_without_tell, :vote
  end
end
