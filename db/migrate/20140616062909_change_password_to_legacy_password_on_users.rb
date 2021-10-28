# frozen_string_literal: true

class ChangePasswordToLegacyPasswordOnUsers < ActiveRecord::Migration
  def change
    rename_column :pw_dyn_user, :password, :legacy_password
  end
end
