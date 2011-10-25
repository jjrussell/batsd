class CreateActionOffers < ActiveRecord::Migration
  def self.up
    create_table :action_offers, :id => false do |t|
      t.column  :id, 'char(36) binary', :null => false
      t.column  :partner_id, 'char(36) binary', :null => false
      t.column  :app_id, 'char(36) binary', :null => false
      t.column  :name, :string, :null => false
      t.text    :instructions
      t.boolean :hidden, :default => false, :null => false
      t.timestamps
    end

    add_index :action_offers, :id, :unique => true
    add_index :action_offers, :partner_id
    add_index :action_offers, :app_id
  end

  def self.down
    drop_table :action_offers
  end
end
