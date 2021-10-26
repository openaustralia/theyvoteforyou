# frozen_string_literal: true

class RemoveActivePolicyIdFromUsers < ActiveRecord::Migration
  def change
    remove_columns :users, :active_policy_id
  end
end
