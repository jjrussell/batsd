class AddExclusionPrerequisiteOfferIdToActionOffers < ActiveRecord::Migration
  def self.up
    add_column :action_offers, :exclusion_prerequisite_offer_ids, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :action_offers, :exclusion_prerequisite_offer_ids
  end
end
