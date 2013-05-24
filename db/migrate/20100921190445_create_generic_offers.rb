class CreateGenericOffers < ActiveRecord::Migration
  def self.up
    create_table :generic_offers, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.string :name, :null => false
      t.text :description
      t.integer :price, :default => 0
      t.string :url, :null => false
      t.string :third_party_data
      t.boolean :hidden, :null => false, :default => false
      t.timestamps
    end

    add_index :generic_offers, :id, :unique => true
    add_index :generic_offers, :partner_id
    add_index :generic_offers, :third_party_data

    add_column :offers, :payment_range_low, :integer
    add_column :offers, :payment_range_high, :integer
  end

  def self.down
    remove_column :offers, :payment_range_high
    remove_column :offers, :payment_range_low

    drop_table :generic_offers
  end
end
