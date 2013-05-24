class CreateSurveyOffers < ActiveRecord::Migration
  def self.up
    create_table :survey_offers, :id => false do |t|
      t.guid    :id, :null => false
      t.guid    :partner_id, :null => false
      t.string  :name, :null => false
      t.boolean :hidden, :default => false, :null => false

      t.timestamps
    end

    add_index :survey_offers, :id, :unique => true
  end

  def self.down
    drop_table :survey_offers
  end
end
