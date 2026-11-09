# frozen_string_literal: true

class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.text :body, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :published, null: false, default: false
      t.timestamps
    end
  end
end
