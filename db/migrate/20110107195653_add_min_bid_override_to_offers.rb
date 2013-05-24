class AddMinBidOverrideToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :min_bid_override, :integer
  end

  def self.down
    remove_column :offers, :min_bid_override
  end
end
