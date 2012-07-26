class AddPrerequisitesToGenericOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :generic_offers, :prerequisite_offer_id
    add_column :generic_offers, :exclusion_prerequisite_offer_ids, :text, :null => false, :default => ''
    add_index :generic_offers, :prerequisite_offer_id
  end

  def self.down
    remove_index :generic_offers, :prerequisite_offer_id
    remove_column :generic_offers, :prerequisite_offer_id
    remove_column :generic_offers, :exclusion_prerequisite_offer_ids
  end
end
