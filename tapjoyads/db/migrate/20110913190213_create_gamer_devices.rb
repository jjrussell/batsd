class CreateGamerDevices < ActiveRecord::Migration
  def self.up
    create_table :gamer_devices, :id => false do |t|
      t.guid   :id,        :null => false
      t.guid   :gamer_id,  :null => false
      t.string :device_id, :null => false
      t.string :name,      :null => false
      t.timestamps
    end
    
    add_index :gamer_devices, :id, :unique => true
    add_index :gamer_devices, :gamer_id
    add_index :gamer_devices, :device_id
  end

  def self.down
    drop_table :gamer_devices
  end
end
