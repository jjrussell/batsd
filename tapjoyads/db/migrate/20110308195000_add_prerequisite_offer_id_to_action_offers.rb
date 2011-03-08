class AddPrerequisiteOfferIdToActionOffers < ActiveRecord::Migration
  def self.up
    add_column :action_offers, :prerequisite_offer_id, 'char(36) binary'
    add_index :action_offers, :prerequisite_offer_id
  end

  def self.down
    remove_index :action_offers, :prerequisite_offer_id
    remove_column :action_offers, :prerequisite_offer_id
  end
end
