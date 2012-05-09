class AddRecoupableAndDevCredits < ActiveRecord::Migration
  def self.up
    add_column :monthly_accountings, :dev_credit_payouts, :integer, :null => false, :default => 0
    add_column :monthly_accountings, :recoupable_marketing_orders, :integer, :null => false, :default => 0
    add_column :monthly_accountings, :recoupable_marketing_payouts, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :monthly_accountings, :dev_credit_payouts
    remove_column :monthly_accountings, :recoupable_marketing_orders
    remove_column :monthly_accountings, :recoupable_marketing_payouts
  end
end
