# frozen_string_literal: true

class CreateEmailSuppressions < ActiveRecord::Migration[8.0]
  def change
    create_table :email_suppressions do |t|
      t.string :address, null: false
      t.string :reason, null: false
      t.string :postal_event
      t.string :reply_excerpt
      t.datetime :suppressed_at, null: false
      t.datetime :lifted_at
      t.timestamps

      t.index %i[address lifted_at]
    end
  end
end
