# frozen_string_literal: true

class ChangeDivisionBinaryColumnsToText < ActiveRecord::Migration
  def change
    change_column :divisions, :source_url, :text
    change_column :divisions, :debate_url, :text
    change_column :divisions, :motion, :text
    change_column :divisions, :notes, :text
  end
end
