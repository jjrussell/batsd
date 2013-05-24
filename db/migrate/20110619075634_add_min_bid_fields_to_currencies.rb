class AddMinBidFieldsToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :minimum_offerwall_bid, :integer
    add_column :currencies, :minimum_display_bid, :integer
  end

  def self.down
    remove_column :currencies, :minimum_offerwall_bid
    remove_column :currencies, :minimum_display_bid
  end
end
