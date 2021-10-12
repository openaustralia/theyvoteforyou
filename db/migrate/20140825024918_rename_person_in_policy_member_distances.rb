# frozen_string_literal: true

class RenamePersonInPolicyMemberDistances < ActiveRecord::Migration
  def change
    rename_column :policy_member_distances, :person, :person_id
  end
end
