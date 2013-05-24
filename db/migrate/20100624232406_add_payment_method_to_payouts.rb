class AddPaymentMethodToPayouts < ActiveRecord::Migration
  def self.up
    add_column :payouts, :payment_method, :integer, :default => 1, :null => false
  end

  def self.down
    remove_column :payouts, :payment_method, :integer
  end
end
