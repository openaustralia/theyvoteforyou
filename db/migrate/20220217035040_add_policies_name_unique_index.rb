class AddPoliciesNameUniqueIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :policies, :name, unique: true
  end
end
