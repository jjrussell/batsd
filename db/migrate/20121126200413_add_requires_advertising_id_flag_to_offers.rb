class AddRequiresAdvertisingIdFlagToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :requires_advertising_id, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :requires_advertising_id
  end
end
