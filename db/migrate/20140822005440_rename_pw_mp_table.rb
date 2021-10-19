# frozen_string_literal: true

class RenamePwMpTable < ActiveRecord::Migration
  def change
    rename_table :pw_mp, :members
  end
end
