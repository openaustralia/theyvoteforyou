# frozen_string_literal: true

class RenamePwCacheMpinfoTable < ActiveRecord::Migration
  def change
    rename_table :pw_cache_mpinfo, :member_infos
  end
end
