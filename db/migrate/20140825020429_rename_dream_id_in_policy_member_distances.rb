# frozen_string_literal: true

class RenameDreamIdInPolicyMemberDistances < ActiveRecord::Migration
  def change
    rename_column :policy_member_distances, :dream_id, :policy_id
  end
end
