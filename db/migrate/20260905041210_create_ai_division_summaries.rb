# frozen_string_literal: true

class CreateAiDivisionSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_division_summaries do |t|
      t.integer :division_id, null: false
      t.string :model, null: false
      t.string :title
      t.text :description
      t.text :raw_response
      t.text :error
      t.timestamps

      t.index :division_id
      t.index %i[division_id model], unique: true
    end
  end
end
