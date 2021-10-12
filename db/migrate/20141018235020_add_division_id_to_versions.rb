# frozen_string_literal: true

class AddDivisionIdToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :division_id, :integer
    add_index :versions, :division_id
  end
end
