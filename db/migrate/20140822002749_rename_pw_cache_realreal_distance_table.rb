class RenamePwCacheRealrealDistanceTable < ActiveRecord::Migration
  def change
    rename_table :pw_cache_realreal_distance, :member_distances
  end
end
