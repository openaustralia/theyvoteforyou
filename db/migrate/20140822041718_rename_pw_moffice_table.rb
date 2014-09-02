class RenamePwMofficeTable < ActiveRecord::Migration
  def change
    rename_table :pw_moffice, :offices
  end
end
