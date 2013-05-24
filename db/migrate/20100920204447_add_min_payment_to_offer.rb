class AddMinPaymentToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :min_payment, :integer
  end

  def self.down
    remove_column :offers, :min_payment
  end
end
