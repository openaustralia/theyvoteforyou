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

      # MySQL has no partial unique index, so this generated column is the address while the suppression is active and
      # NULL once it is lifted. Unique indexes allow many NULLs, so only one active row per address can exist, even
      # when two bounce reports for it are handled at once.
      t.virtual :active_address, type: :string, as: "IF(lifted_at IS NULL, address, NULL)", stored: false

      t.index %i[address lifted_at]
      t.index :active_address, unique: true
    end
  end
end
