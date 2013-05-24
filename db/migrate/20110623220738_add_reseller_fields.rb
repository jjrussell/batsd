class AddResellerFields < ActiveRecord::Migration
  def self.up
    create_table :resellers, :id => false do |t|
      t.guid :id, :null => false
      t.string :name
      t.decimal :reseller_rev_share, :precision => 8, :scale => 6, :null => false
      t.decimal :rev_share, :precision => 8, :scale => 6, :null => false
      t.timestamps
    end

    add_index :resellers, :id, :unique => true

    add_guid_column :users, :reseller_id

    add_guid_column :partners, :reseller_id
    add_index :partners, :reseller_id

    add_guid_column :currencies, :reseller_id
    add_column :currencies, :reseller_spend_share, :decimal, :precision => 8, :scale => 6
    add_index :currencies, :reseller_id

    add_guid_column :offers, :reseller_id
  end

  def self.down
    drop_table :resellers
    remove_column :users, :reseller_id
    remove_column :partners, :reseller_id
    remove_column :currencies, :reseller_id
    remove_column :currencies, :reseller_spend_share
    remove_column :offers, :reseller_id
  end
end
