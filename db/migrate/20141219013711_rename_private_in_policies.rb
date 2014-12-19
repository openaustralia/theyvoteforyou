class RenamePrivateInPolicies < ActiveRecord::Migration
  def change
    rename_column :policies, :private, :status
  end
end
