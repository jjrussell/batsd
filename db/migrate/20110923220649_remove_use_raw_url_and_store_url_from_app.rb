class RemoveUseRawUrlAndStoreUrlFromApp < ActiveRecord::Migration
  def self.up
    remove_column :apps, :use_raw_url
    remove_column :apps, :store_url
  end

  def self.down
    add_column :apps, :store_url, :text
    add_column :apps, :use_raw_url, :boolean
  end
end
