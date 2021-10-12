# frozen_string_literal: true

class RemoveNotesFromDivisions < ActiveRecord::Migration
  def change
    remove_column :divisions, :notes, :text, null: false
  end
end
