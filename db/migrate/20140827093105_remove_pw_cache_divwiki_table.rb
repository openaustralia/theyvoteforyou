# frozen_string_literal: true

class RemovePwCacheDivwikiTable < ActiveRecord::Migration
  def change
    drop_table :pw_cache_divwiki
  end
end
