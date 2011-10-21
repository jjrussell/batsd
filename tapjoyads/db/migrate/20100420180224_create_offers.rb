class CreateOffers < ActiveRecord::Migration
  def self.up
    create_table :offers, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.column :item_id, 'char(36) binary', :null => false
      t.string :item_type, :null => false
      t.string :name, :null => false
      t.text :description
      t.text :url
      t.integer :price
      t.integer :payment
      t.integer :actual_payment
      t.integer :daily_budget
      t.integer :overall_budget
      t.integer :ordinal, :default => 500, :null => false
      t.text :countries
      t.text :cities
      t.text :postal_codes
      t.text :device_types
      t.boolean :pay_per_click, :default => false
      t.boolean :allow_negative_balance, :default => false
      t.boolean :user_enabled, :default => false
      t.boolean :tapjoy_enabled, :default => false
      t.timestamps
    end

    add_index :offers, :id, :unique => true
    add_index :offers, :partner_id
    add_index :offers, :item_id, :unique => true
    add_index :offers, [ :item_type, :item_id ], :unique => true
    add_index :offers, :name
    add_index :offers, :ordinal
    add_index :offers, [ :user_enabled, :tapjoy_enabled ]
  end

  def self.down
    drop_table :offers
  end
end
