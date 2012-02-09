class CreatePromotedOffers < ActiveRecord::Migration
  def self.up
    create_table :global_promoted_offers, :id => false do |t|
      t.guid :id, :null => false
      t.guid :partner_id, :null => false
      t.guid :offer_id, :null => false
    end
    add_index :global_promoted_offers, :id, :unique => true
    add_index :global_promoted_offers, :partner_id

    create_table :promoted_offers, :id => false do |t|
      t.guid :id, :null => false
      t.guid :app_id, :null => false
      t.guid :offer_id, :null => false
    end
    add_index :promoted_offers, :id, :unique => true
    add_index :promoted_offers, :app_id
  end

  def self.down
    drop_table :global_promoted_offers
    drop_table :promoted_offers
  end
end
