# frozen_string_literal: true

class RenamePwConstituencyTable < ActiveRecord::Migration
  def change
    rename_table :pw_constituency, :electorates
  end
end
