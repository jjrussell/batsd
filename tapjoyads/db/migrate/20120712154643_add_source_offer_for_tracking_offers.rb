class AddSourceOfferForTrackingOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :offers, :source_offer_id
    add_index :offers, [ :source_offer_id ]
  end

  def self.down
    remove_index :offers, [ :source_offer_id ]
    remove_column :offers, :source_offer_id
  end
end
