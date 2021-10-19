# frozen_string_literal: true

class DropUnusedTablesInRails < ActiveRecord::Migration
  def change
    drop_table :pw_cache_attendrank_today
    drop_table :pw_cache_divdiv_distance
    drop_table :pw_cache_dreaminfo
    drop_table :pw_cache_partyinfo
    drop_table :pw_cache_rebelrank_today
    drop_table :pw_candidate
    drop_table :pw_dyn_aggregate_dreammp
    drop_table :pw_dyn_auditlog
    drop_table :pw_dyn_newsletter
    drop_table :pw_dyn_newsletters_sent
    drop_table :pw_logincoming
  end
end
