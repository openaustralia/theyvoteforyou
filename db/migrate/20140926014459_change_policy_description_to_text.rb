class ChangePolicyDescriptionToText < ActiveRecord::Migration
  def change
    change_column :policies, :description, :text
  end
end
