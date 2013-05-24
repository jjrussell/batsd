class CreateEmailOffers < ActiveRecord::Migration
  def self.up
    create_table :email_offers, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.string :name, :null => false
      t.text :description
      t.string :third_party_id
      t.timestamps
    end

    add_index :email_offers, :id, :unique => true
    add_index :email_offers, :partner_id
    add_index :email_offers, :name
  end

  def self.down
    drop_table :email_offers
  end
end
