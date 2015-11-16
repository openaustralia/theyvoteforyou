class AddNotVotingVotesToWhips < ActiveRecord::Migration
  def change
    add_column :whips, :not_voting_votes, :integer
  end
end
