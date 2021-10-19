# frozen_string_literal: true

class RenamePwCacheRealrealDistanceTable < ActiveRecord::Migration
  def change
    rename_table :pw_cache_realreal_distance, :member_distances
  end
end
