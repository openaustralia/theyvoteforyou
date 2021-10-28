# frozen_string_literal: true

class RemoveLimitsFromFieldsOnOffices < ActiveRecord::Migration
  def change
    change_column :offices, :dept, :string, limit: nil
    change_column :offices, :position, :string, limit: nil
    change_column :offices, :responsibility, :string, limit: nil
  end
end
