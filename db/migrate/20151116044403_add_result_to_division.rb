class AddResultToDivision < ActiveRecord::Migration
  def change
    add_column :divisions, :result, :string
  end
end
