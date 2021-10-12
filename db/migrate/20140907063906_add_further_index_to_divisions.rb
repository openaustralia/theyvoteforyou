class AddFurtherIndexToDivisions < ActiveRecord::Migration
  def change
    change_column :divisions, :clock_time, :string
    add_index :divisions, %i[id date clock_time]
  end
end
