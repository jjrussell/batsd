class AddCountriesBlacklistToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :countries_blacklist, :text
  end

  def self.down
    remove_column :apps, :countries_blacklist
  end
end
