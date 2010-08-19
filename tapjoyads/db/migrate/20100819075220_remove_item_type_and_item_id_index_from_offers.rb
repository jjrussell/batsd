class RemoveItemTypeAndItemIdIndexFromOffers < ActiveRecord::Migration
  def self.up
    remove_index :offers, :name => 'index_offers_on_item_type_and_item_id'
  end

  def self.down
    add_index :offers, [ :item_type, :item_id ], :unique => true
  end
end
