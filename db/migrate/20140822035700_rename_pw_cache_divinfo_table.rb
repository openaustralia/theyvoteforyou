class RenamePwCacheDivinfoTable < ActiveRecord::Migration
  def change
    rename_table :pw_cache_divinfo, :division_infos
  end
end
