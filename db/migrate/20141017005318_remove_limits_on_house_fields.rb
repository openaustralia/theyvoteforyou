# frozen_string_literal: true

class RemoveLimitsOnHouseFields < ActiveRecord::Migration
  def change
    change_column :divisions, :house, :string, limit: nil
    change_column :electorates, :house, :string, limit: nil
    change_column :members, :house, :string, limit: nil
  end
end
