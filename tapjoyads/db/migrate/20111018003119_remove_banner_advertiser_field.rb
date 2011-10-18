class RemoveBannerAdvertiserField < ActiveRecord::Migration
  def self.up
    remove_column :currencies, :banner_advertiser
  end

  def self.down
    add_column :currencies, :banner_advertiser, :boolean, :null => false, :default => false
  end
end
