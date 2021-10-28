# frozen_string_literal: true

class RemoveUserNameFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :user_name, :text
  end
end
