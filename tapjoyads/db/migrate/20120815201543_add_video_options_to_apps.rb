class AddVideoOptionsToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :videos_enabled,    :boolean, :default => true,  :null => false
    add_column :apps, :videos_cache_auto, :boolean, :default => false, :null => false
    add_column :apps, :videos_cache_wifi, :boolean, :default => false, :null => false
    add_column :apps, :videos_cache_3g,   :boolean, :default => false, :null => false
    add_column :apps, :videos_stream_3g,  :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :apps, :videos_enabled
    remove_column :apps, :videos_cache_auto
    remove_column :apps, :videos_cache_wifi
    remove_column :apps, :videos_cache_3g
    remove_column :apps, :videos_stream_3g
  end
end
