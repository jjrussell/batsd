class CreateAdminDevices < ActiveRecord::Migration
  def self.up
    create_table :admin_devices, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.string :udid
      t.string :description
      t.string :platform

      t.timestamps
    end

    add_index :admin_devices, :id, :unique => true
    add_index :admin_devices, :udid, :unique => true
    add_index :admin_devices, :description, :unique => true
  end

  def self.down
    drop_table :admin_devices
  end
end
