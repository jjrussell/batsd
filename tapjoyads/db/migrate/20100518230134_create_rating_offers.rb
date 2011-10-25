class CreateRatingOffers < ActiveRecord::Migration
  def self.up
    create_table :rating_offers, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.column :app_id, 'char(36) binary', :null => false
      t.string :name, :null => false
      t.text :description
      t.text :instructions
      t.timestamps
    end

    add_index :rating_offers, :id, :unique => true
    add_index :rating_offers, :partner_id
    add_index :rating_offers, :app_id
  end

  def self.down
    drop_table :rating_offers
  end
end
