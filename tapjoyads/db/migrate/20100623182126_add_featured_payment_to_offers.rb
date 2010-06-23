class AddFeaturedPaymentToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :featured_payment, :integer
  end

  def self.down
    remove_column :offers, :featured_payment
  end
end
