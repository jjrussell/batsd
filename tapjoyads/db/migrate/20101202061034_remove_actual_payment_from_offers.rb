class RemoveActualPaymentFromOffers < ActiveRecord::Migration
  def self.up
    remove_column :offers, :actual_payment
  end

  def self.down
    add_column :offers, :actual_payment, :integer
  end
end
