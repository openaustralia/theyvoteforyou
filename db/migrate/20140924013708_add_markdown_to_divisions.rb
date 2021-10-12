# frozen_string_literal: true

class AddMarkdownToDivisions < ActiveRecord::Migration
  def change
    add_column :divisions, :markdown, :boolean, null: false, default: false
  end
end
