class CreateOfferpalOffers < ActiveRecord::Migration
  def self.up
    create_table :offerpal_offers, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.string :offerpal_id, :null => false
      t.string :name, :null => false
      t.text :description
      t.timestamps
    end

    add_index :offerpal_offers, :id, :unique => true
    add_index :offerpal_offers, :partner_id
    add_index :offerpal_offers, :offerpal_id, :unique => true
    add_index :offerpal_offers, :name
  end

  def self.down
    drop_table :offerpal_offers
  end
end
