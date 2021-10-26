# frozen_string_literal: true

class MakeMarkdownDefaultInDivisions < ActiveRecord::Migration
  def change
    change_column :divisions, :markdown, :boolean, default: true
  end
end
