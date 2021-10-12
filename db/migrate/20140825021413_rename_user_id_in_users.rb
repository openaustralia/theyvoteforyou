# frozen_string_literal: true

class RenameUserIdInUsers < ActiveRecord::Migration
  def change
    rename_column :users, :user_id, :id
  end
end
