class CreateConversions < ActiveRecord::Migration
  def self.up
    create_table :conversions, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :reward_id, 'char(36) binary'
      t.column :advertiser_app_id, 'char(36) binary'
      t.column :publisher_app_id, 'char(36) binary', :null => false
      t.integer :advertiser_amount, :null => false
      t.integer :publisher_amount, :null => false
      t.integer :tapjoy_amount, :null => false
      t.integer :reward_type, :null => false
      t.timestamps
    end

    add_index :conversions, :id, :unique => true
  end

  def self.down
    drop_table :conversions
  end
end
