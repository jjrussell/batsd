class AddFlagsToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :requires_udid, :boolean, :null => false, :default => false
    add_column :offers, :requires_mac_address, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :requires_mac_address
    remove_column :offers, :requires_udid
  end
end
