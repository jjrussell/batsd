class AddColumnsToGamerDevices < ActiveRecord::Migration
  def self.up
    add_column :gamer_devices, :device_type, :string
  end
  
  def self.down
    remove_column :gamer_devices, :device_type
  end
end