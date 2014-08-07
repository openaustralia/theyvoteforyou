class AddConfirmableToDevise < ActiveRecord::Migration
  def self.up
    add_column :pw_dyn_user, :confirmation_token, :string
    add_column :pw_dyn_user, :confirmed_at, :datetime
    add_column :pw_dyn_user, :confirmation_sent_at, :datetime
    add_column :pw_dyn_user, :unconfirmed_email, :string
    add_index :pw_dyn_user, :confirmation_token, :unique => true

    User.update_all(:confirmed_at => Time.now)
  end

  def self.down
    remove_columns :pw_dyn_user, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
  end
end
