# frozen_string_literal: true

class RenameRealNameToNameInUsers < ActiveRecord::Migration
  def change
    rename_column :users, :real_name, :name
  end
end
