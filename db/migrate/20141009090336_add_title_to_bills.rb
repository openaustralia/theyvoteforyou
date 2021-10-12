# frozen_string_literal: true

class AddTitleToBills < ActiveRecord::Migration
  def change
    add_column :bills, :title, :text
  end
end
