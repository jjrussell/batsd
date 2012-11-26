class AddTapjoyDeviceIdToAdminDevices < ActiveRecord::Migration
  def self.up
    add_column :admin_devices, :tapjoy_device_id, :string
  end

  def self.down
    remove_column :admin_devices, :tapjoy_device_id
  end
end
