class AddPrerequisitesToVideoOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :video_offers, :prerequisite_offer_id
    add_guid_column :video_offers, :negative_prerequisite_offer_id
    add_index :video_offers, :prerequisite_offer_id
    add_index :video_offers, :negative_prerequisite_offer_id
  end

  def self.down
    remove_index :video_offers, :prerequisite_offer_id
    remove_index :video_offers, :negative_prerequisite_offer_id
    remove_column :video_offers, :prerequisite_offer_id
    remove_column :video_offers, :negative_prerequisite_offer_id
  end
end
