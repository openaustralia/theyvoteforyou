# frozen_string_literal: true

class RemoveVoteFromVotes < ActiveRecord::Migration
  def change
    remove_column :votes, :vote, :string, limit: 10, null: false
  end
end
