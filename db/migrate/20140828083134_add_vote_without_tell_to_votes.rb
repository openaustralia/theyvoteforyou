# frozen_string_literal: true

class AddVoteWithoutTellToVotes < ActiveRecord::Migration
  def change
    add_column :votes, :vote_without_tell, :string, limit: 10
    add_index :votes, :vote_without_tell
    add_column :votes, :teller, :boolean, null: false, default: false
    add_index :votes, :teller
    Vote.reset_column_information
    Vote.all.find_each do |vote|
      case vote.vote
      when "tellaye"
        vote.update!(vote_without_tell: "aye", teller: true)
      when "tellno"
        vote.update!(vote_without_tell: "no", teller: true)
      else
        vote.update!(vote_without_tell: vote.vote)
      end
    end
  end
end
