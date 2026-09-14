# frozen_string_literal: true

class CreateAiPolicySuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_policy_suggestions do |t|
      t.integer :division_id, null: false
      t.integer :policy_id
      t.string :model, null: false
      t.string :match
      t.string :direction
      t.string :proposed_policy_name
      t.text :proposed_policy_description
      t.text :reasoning
      t.text :raw_response
      t.text :error
      t.timestamps

      t.index :division_id
      t.index :policy_id
      t.index %i[division_id model], unique: true
    end
  end
end
