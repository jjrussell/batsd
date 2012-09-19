class AddExclusionAppsToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :exclusion_apps, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :apps, :exclusion_apps
  end
end
