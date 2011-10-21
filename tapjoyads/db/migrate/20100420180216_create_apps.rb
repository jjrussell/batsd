class CreateApps < ActiveRecord::Migration
  def self.up
    create_table :apps, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.string :name, :null => false
      t.text :description
      t.integer :price, :default => 0
      t.string :platform
      t.string :store_id
      t.text :store_url
      t.integer :color
      t.boolean :use_raw_url, :default => false, :null => false
      t.datetime :first_pinged_at
      t.datetime :submitted_to_store_at
      t.datetime :approved_by_store_at
      t.datetime :approved_by_tapjoy_at
      t.datetime :enabled_at
      t.timestamps
    end

    add_index :apps, :id, :unique => true
    add_index :apps, :partner_id
    add_index :apps, :name
  end

  def self.down
    drop_table :apps
  end
end
