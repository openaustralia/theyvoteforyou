# frozen_string_literal: true

class RenamePwCacheDreamrealDistanceTable < ActiveRecord::Migration
  def change
    rename_table :pw_cache_dreamreal_distance, :policy_member_distances
  end
end
