# frozen_string_literal: true

class RenameMpIdColumnInMembers < ActiveRecord::Migration
  def change
    rename_column :members, :mp_id, :id
  end
end
