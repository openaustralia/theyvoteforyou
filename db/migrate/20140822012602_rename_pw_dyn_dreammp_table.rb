# frozen_string_literal: true

class RenamePwDynDreammpTable < ActiveRecord::Migration
  def change
    rename_table :pw_dyn_dreammp, :policies
  end
end
