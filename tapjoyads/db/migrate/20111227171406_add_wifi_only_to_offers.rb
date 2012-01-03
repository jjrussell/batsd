class AddWifiOnlyToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :wifi_only, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :wifi_only
  end
end
