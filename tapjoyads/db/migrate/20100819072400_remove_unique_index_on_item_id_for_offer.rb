class RemoveUniqueIndexOnItemIdForOffer < ActiveRecord::Migration
  def self.up
    remove_index :offers, :item_id
    add_index :offers, :item_id
  end

  def self.down
    remove_index :offers, :item_id
    add_index :offers, :item_id, :unique => true
  end
end
