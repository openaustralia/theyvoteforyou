# frozen_string_literal: true

class CreateWatches < ActiveRecord::Migration
  def change
    create_table :watches do |t|
      t.integer :watchable_id
      t.string :watchable_type
      t.integer :user_id
    end
  end
end
