# frozen_string_literal: true

class MultipleBillsInDivisions < ActiveRecord::Migration
  def change
    remove_column :divisions, :bill_id, :string
    remove_column :divisions, :bill_url, :text
    create_table :bills do |t|
      t.string :official_id
      t.text :url
      t.timestamps
    end
    create_join_table :divisions, :bills
  end
end
