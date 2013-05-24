class AddPrerequisitesToOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :offers, :prerequisite_offer_id
    add_column :offers, :exclusion_prerequisite_offer_ids, :text, :null => false, :default => ''
    add_index :offers, :prerequisite_offer_id
  end

  def self.down
    remove_index :offers, :prerequisite_offer_id
    remove_column :offers, :prerequisite_offer_id
    remove_column :offers, :exclusion_prerequisite_offer_ids
  end
end
