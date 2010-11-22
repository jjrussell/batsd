class AddMinimumFeaturedBidToCurrency < ActiveRecord::Migration
  def self.up
    add_column :currencies, :minimum_featured_bid, :integer
  end

  def self.down
    remove_column :currencies, :minimum_featured_bid
  end
end
