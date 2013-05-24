class CreateInternalDevices < ActiveRecord::Migration
  def self.up
    create_table :internal_devices, :id => false do |t|
      t.guid :id, :null => false
      t.column :user_id, 'char(36) binary', :null => false
      t.string :description
      t.string :status
      t.integer :verification_key

      t.timestamps
    end

    add_index :internal_devices, :id, :unique => true
    add_index :internal_devices, :user_id
  end

  def self.down
    drop_table :internal_devices
  end
end
