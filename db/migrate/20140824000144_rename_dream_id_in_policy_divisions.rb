# frozen_string_literal: true

class RenameDreamIdInPolicyDivisions < ActiveRecord::Migration
  def change
    rename_column :policy_divisions, :dream_id, :policy_id
  end
end
