class DropSortOrdersTable < ActiveRecord::Migration
  def change
    drop_table :vote_sortorders
  end
end
