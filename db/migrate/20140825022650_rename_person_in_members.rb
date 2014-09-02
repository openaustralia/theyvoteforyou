class RenamePersonInMembers < ActiveRecord::Migration
  def change
    rename_column :members, :person, :person_id
  end
end
