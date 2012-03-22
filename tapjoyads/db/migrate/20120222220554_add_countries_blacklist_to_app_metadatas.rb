class AddCountriesBlacklistToAppMetadatas < ActiveRecord::Migration
  def self.up
    add_column :app_metadatas, :countries_blacklist, :text
  end

  def self.down
    remove_column :app_metadatas, :countries_blacklist
  end
end
