# frozen_string_literal: true

class RenamePersonInOffices < ActiveRecord::Migration
  def change
    rename_column :offices, :person, :person_id
  end
end
