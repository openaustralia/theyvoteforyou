# frozen_string_literal: true

class CreateApiStatistics < ActiveRecord::Migration
  def change
    create_table :api_statistics do |t|
      t.string :ip_address
      t.text :query
      t.text :user_agent
      t.integer :user_id

      t.timestamps
    end
  end
end
