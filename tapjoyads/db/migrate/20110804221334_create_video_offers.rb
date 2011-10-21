class CreateVideoOffers < ActiveRecord::Migration
  def self.up
    create_table :video_offers, :id => false do |t|
      t.guid    :id, :null => false
      t.guid    :partner_id, :null => false
      t.string  :name, :null => false
      t.boolean :hidden, :default => false, :null => false
      t.string  :video_url
      t.timestamps
    end

    add_index :video_offers, :id, :unique => true
    add_index :video_offers, :partner_id
  end

  def self.down
    drop_table :video_offers
  end
end
