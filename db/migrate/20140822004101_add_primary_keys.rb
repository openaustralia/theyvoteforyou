# frozen_string_literal: true

class AddPrimaryKeys < ActiveRecord::Migration
  def change
    add_column :member_distances, :id, :primary_key
    add_column :pw_cache_divinfo, :id, :primary_key
    add_column :pw_cache_divwiki, :id, :primary_key
    add_column :pw_cache_dreamreal_distance, :id, :primary_key
    add_column :pw_cache_mpinfo, :id, :primary_key
    add_column :pw_cache_whip, :id, :primary_key
    add_column :pw_constituency, :id, :primary_key
    add_column :pw_dyn_dreamvote, :id, :primary_key
    add_column :pw_vote, :id, :primary_key
    add_column :pw_vote_sortorder, :id, :primary_key
  end
end
