class AddMarketingCreditsTypeToMonthlyAccounting < ActiveRecord::Migration
  def self.up
    add_column :monthly_accountings, :bonus_orders, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :monthly_accountings, :bonus_orders
  end
end
