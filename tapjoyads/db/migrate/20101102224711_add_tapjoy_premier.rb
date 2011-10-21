class AddTapjoyPremier < ActiveRecord::Migration
  def self.up
    add_column :partners, :premier_discount, :integer, :default => 0, :null => false
    add_column :partners, :exclusivity_level_type, :string
    add_column :partners, :exclusivity_expires_on, :date
    add_column :offers, :bid, :integer, :default => 0, :null => false

    create_table :offer_discounts, :id => false do |t|
      t.column    :id, 'char(36) binary', :null => false
      t.column    :partner_id, 'char(36) binary', :null => false
      t.string    :source, :null => false
      t.date      :expires_on, :null => false
      t.integer   :amount, :null => false
      t.timestamps
    end

    add_index :offer_discounts, :id, :unique => true
    add_index :offer_discounts, :partner_id
  end

  def self.down
    drop_table :offer_discounts

    remove_column :partners, :premier_discount
    remove_column :partners, :exclusivity_level_type
    remove_column :partners, :exclusivity_expires_on
    remove_column :offers, :bid
  end
end
