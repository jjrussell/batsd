class AddPrerequisitesToGenericOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :generic_offers, :prerequisite_offer_id
    add_guid_column :generic_offers, :negative_prerequisite_offer_id
    add_index :generic_offers, :prerequisite_offer_id
    add_index :generic_offers, :negative_prerequisite_offer_id
  end

  def self.down
    remove_index :generic_offers, :prerequisite_offer_id
    remove_index :generic_offers, :negative_prerequisite_offer_id
    remove_column :generic_offers, :prerequisite_offer_id
    remove_column :generic_offers, :negative_prerequisite_offer_id
  end
end
