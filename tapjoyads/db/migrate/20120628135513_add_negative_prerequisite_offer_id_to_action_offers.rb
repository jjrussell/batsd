class AddNegativePrerequisiteOfferIdToActionOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :action_offers, :negative_prerequisite_offer_id
    add_index :action_offers, :negative_prerequisite_offer_id
  end

  def self.down
    remove_index :action_offers, :negative_prerequisite_offer_id
    remove_column :action_offers, :negative_prerequisite_offer_id
  end
end
