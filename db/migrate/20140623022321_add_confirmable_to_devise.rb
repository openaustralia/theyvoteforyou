# frozen_string_literal: true

class AddConfirmableToDevise < ActiveRecord::Migration
  def self.up
    add_column :pw_dyn_user, :confirmation_token, :string
    add_column :pw_dyn_user, :confirmed_at, :datetime
    add_column :pw_dyn_user, :confirmation_sent_at, :datetime
    add_column :pw_dyn_user, :unconfirmed_email, :string
    add_index :pw_dyn_user, :confirmation_token, unique: true

    # Temporarily use old table name
    user_table_name = User.table_name
    User.table_name = "pw_dyn_user"
    # Update existing records
    User.update_all(confirmed_at: Time.now)
    # Reset table name
    User.table_name = user_table_name
  end

  def self.down
    remove_columns :pw_dyn_user, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
  end
end
