class AddBannerAdvertiserToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :banner_advertiser, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :currencies, :banner_advertiser
  end
end
