# frozen_string_literal: true

class AddBillToDivisions < ActiveRecord::Migration
  def change
    add_column :divisions, :bill_id, :string
    add_column :divisions, :bill_url, :text
  end
end
