class RenamePwCacheWhipTable < ActiveRecord::Migration
  def change
    rename_table :pw_cache_whip, :whips
  end
end
