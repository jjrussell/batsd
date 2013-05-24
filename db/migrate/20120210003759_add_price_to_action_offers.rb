class AddPriceToActionOffers < ActiveRecord::Migration
  def self.up
    add_column :action_offers, :price, :integer, :default => 0
  end

  def self.down
    remove_column :action_offers, :price
  end
end
