class AddUserIdToAdminDevices < ActiveRecord::Migration
  def self.up
    add_column :admin_devices, :user_id, 'char(36) binary'
  end

  def self.down
    remove_column :admin_devices, :user_id
  end
end
