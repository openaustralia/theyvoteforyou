# frozen_string_literal: true

# One row per file an admin uploads for processing later (see Ingest). `kind` says what the file
# holds and so which processor reads it; the only kind so far is "division-summary".
class CreateIngests < ActiveRecord::Migration[8.0]
  def change
    create_table :ingests do |t|
      t.string :kind, null: false
      t.string :status, null: false, default: "queued"
      t.integer :user_id
      t.string :original_filename
      t.string :file_path
      t.integer :records_saved, null: false, default: 0
      t.text :error
      t.datetime :processed_at
      t.timestamps

      t.index %i[kind status]
      t.index :user_id
    end
  end
end
