class CreateReengagementOffers < ActiveRecord::Migration
  def self.up
    create_table :reengagement_offers, :id => false do |t|
      t.guid :id, :null => false
      t.guid :app_id, :null => false
      t.guid :partner_id, :null => false
      t.guid :currency_id, :null => false
      t.guid :prerequisite_offer_id
      t.text :instructions
      t.integer :day_number, :null => false
      
      t.timestamps
    end

    add_index :reengagement_offers, :id
    add_index :reengagement_offers, :app_id
  end

  def self.down
    drop_table :reengagement_offers
  end
end
