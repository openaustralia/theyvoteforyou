# frozen_string_literal: true

class CreateDailyApiUsages < ActiveRecord::Migration[8.1]
  def change
    # A plain integer with no foreign key, like api_statistics.user_id: production's users.id is an int
    # (from the original PHP table), not the bigint schema.rb shows, so a bigint foreign key would fail there.
    create_table :daily_api_usages do |t|
      t.integer :user_id, null: false
      t.date :date, null: false
      t.integer :count, null: false, default: 0
    end
    add_index :daily_api_usages, %i[user_id date], unique: true
    add_index :daily_api_usages, :date
  end
end
