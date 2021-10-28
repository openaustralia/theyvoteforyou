# frozen_string_literal: true

class DropDivisionDateNumberHouseInPolicyDivisions < ActiveRecord::Migration
  def change
    remove_index :policy_divisions, name: "division_date_2"
    add_index :policy_divisions, %i[division_id policy_id], unique: true
    add_index :policy_divisions, :division_id
    remove_column :policy_divisions, :division_date, :date, null: false
    remove_column :policy_divisions, :division_number, :integer, null: false
    remove_column :policy_divisions, :house, :string, limit: 8, null: false
  end
end
