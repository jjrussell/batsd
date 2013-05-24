class AddRequiresAdminDeviceToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :requires_admin_device, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :offers, :requires_admin_device
  end
end
