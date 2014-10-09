class AddTitleToBills < ActiveRecord::Migration
  def change
    add_column :bills, :title, :text
  end
end
