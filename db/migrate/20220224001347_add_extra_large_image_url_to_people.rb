class AddExtraLargeImageUrlToPeople < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :extra_large_image_url, :text
  end
end
