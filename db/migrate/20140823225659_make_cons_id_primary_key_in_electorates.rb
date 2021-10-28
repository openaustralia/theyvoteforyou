# frozen_string_literal: true

class MakeConsIdPrimaryKeyInElectorates < ActiveRecord::Migration
  def change
    remove_column :electorates, :id
    rename_column :electorates, :cons_id, :id
    change_column :electorates, :id, :primary_key
  end
end
