class ConvertUsersTextFieldsToString < ActiveRecord::Migration[6.0]
  def up
    # Temporary columns to hold truncated values
    add_column :users, :temp_name, :string, null: false
    add_column :users, :temp_email, :string

    # There's only spam accounts that have long names or emails. So we can just chop them off
    User.find_each do |user|
      user.update(temp_name: user.name[0..254], temp_email: user.email&.[](0..254))
    end

    remove_column :users, :name
    rename_column :users, :temp_name, :name

    remove_column :users, :email
    rename_column :users, :temp_email, :email
  end

  def down
    change_column :users, :name, :text, null: false
    change_column :users, :email, :text
  end
end
