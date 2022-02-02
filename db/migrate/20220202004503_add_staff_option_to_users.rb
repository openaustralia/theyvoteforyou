class AddStaffOptionToUsers < ActiveRecord::Migration[6.0]
  def change
    # Used to show to the public whether a user is currently (or a past) staff member of the OpenAustralia Foundation
    # This is to add extra weight to edits made by those people
    add_column :users, :staff, :boolean, null: false, default: false
  end
end
