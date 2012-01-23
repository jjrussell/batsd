class AddMarketingCreditsTypeToMonthlyAccounting < ActiveRecord::Migration
  def self.up
    add_column :monthly_accountings, :marketing_credits_orders, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :monthly_accountings, :marketing_credits_orders
  end
end
