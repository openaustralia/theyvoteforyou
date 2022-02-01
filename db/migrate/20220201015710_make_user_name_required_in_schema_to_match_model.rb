class MakeUserNameRequiredInSchemaToMatchModel < ActiveRecord::Migration[6.0]
  def change
    change_column_null :users, :name, false
  end
end
