# frozen_string_literal: true

class AddPolicyIdToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :policy_id, :integer
    add_index :versions, :policy_id
  end
end
