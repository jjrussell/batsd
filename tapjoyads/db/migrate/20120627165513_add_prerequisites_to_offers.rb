class AddPrerequisitesToOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :offers, :prerequisite_offer_id
    add_guid_column :offers, :negative_prerequisite_offer_id
    add_index :offers, :prerequisite_offer_id
    add_index :offers, :negative_prerequisite_offer_id
  end

  def self.down
    remove_index :offers, :prerequisite_offer_id
    remove_index :offers, :negative_prerequisite_offer_id
    remove_column :offers, :prerequisite_offer_id
    remove_column :offers, :negative_prerequisite_offer_id
  end
end
