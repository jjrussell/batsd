class ChangeMonthlyAccountingDefaults < ActiveRecord::Migration
  def self.up
    change_column_default :monthly_accountings, :beginning_balance, 0
    change_column_default :monthly_accountings, :ending_balance, 0
    change_column_default :monthly_accountings, :website_orders, 0
    change_column_default :monthly_accountings, :invoiced_orders, 0
    change_column_default :monthly_accountings, :marketing_orders, 0
    change_column_default :monthly_accountings, :transfer_orders, 0
    change_column_default :monthly_accountings, :spend, 0
    change_column_default :monthly_accountings, :beginning_pending_earnings, 0
    change_column_default :monthly_accountings, :ending_pending_earnings, 0
    change_column_default :monthly_accountings, :payment_payouts, 0
    change_column_default :monthly_accountings, :transfer_payouts, 0
    change_column_default :monthly_accountings, :earnings, 0
  end

  def self.down
    # can't change default to null without using direct sql statements
  end
end
