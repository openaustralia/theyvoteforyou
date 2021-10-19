# frozen_string_literal: true

class RenameDreamIdInPolicies < ActiveRecord::Migration
  def change
    rename_column :policies, :dream_id, :id
  end
end
