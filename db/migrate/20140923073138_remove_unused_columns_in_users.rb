class RemoveUnusedColumnsInUsers < ActiveRecord::Migration
  def change
    remove_columns :users, :legacy_password, :remote_addr, :confirm_hash, :confirm_return_url,
                   :is_confirmed, :reg_date
  end
end
