class RenamePwConstituencyTable < ActiveRecord::Migration
  def change
    rename_table :pw_constituency, :electorates
  end
end
