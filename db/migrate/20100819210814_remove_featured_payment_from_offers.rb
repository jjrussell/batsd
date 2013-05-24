class RemoveFeaturedPaymentFromOffers < ActiveRecord::Migration
  def self.up
    remove_column :offers, :featured_payment
  end

  def self.down
    add_column :offers, :featured_payment, :integer
  end
end
