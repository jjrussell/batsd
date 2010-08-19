class AddNonUniqueItemTypeAndItemIdIndexToOffers < ActiveRecord::Migration
  def self.up
    add_index :offers, [ :item_type, :item_id ]
  end

  def self.down
    remove_index :offers, :name => 'index_offers_on_item_type_and_item_id'
  end
end
