# frozen_string_literal: true

class AddImagesUrlsToPeople < ActiveRecord::Migration
  def change
    add_column :people, :small_image_url, :text
    add_column :people, :large_image_url, :text
  end
end
