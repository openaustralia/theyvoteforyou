# frozen_string_literal: true

class RenameMofficeIdInOffices < ActiveRecord::Migration
  def change
    rename_column :offices, :moffice_id, :id
  end
end
