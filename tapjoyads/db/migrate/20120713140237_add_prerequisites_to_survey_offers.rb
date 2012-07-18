class AddPrerequisitesToSurveyOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :survey_offers, :prerequisite_offer_id
    add_column :survey_offers, :exclusion_prerequisite_offer_ids, :text, :null => false, :default => ''
    add_index :survey_offers, :prerequisite_offer_id
  end

  def self.down
    remove_index :survey_offers, :prerequisite_offer_id
    remove_column :survey_offers, :prerequisite_offer_id
    remove_column :survey_offers, :exclusion_prerequisite_offer_ids
  end
end
