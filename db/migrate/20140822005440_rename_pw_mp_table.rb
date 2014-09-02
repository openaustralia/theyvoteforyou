class RenamePwMpTable < ActiveRecord::Migration
  def change
    rename_table :pw_mp, :members
  end
end
