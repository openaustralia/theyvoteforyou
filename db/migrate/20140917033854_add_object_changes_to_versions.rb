# frozen_string_literal: true

class AddObjectChangesToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :object_changes, :text
  end
end
