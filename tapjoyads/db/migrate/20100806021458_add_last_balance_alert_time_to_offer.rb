class AddLastBalanceAlertTimeToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :last_balance_alert_time, :timestamp
  end

  def self.down
    remove_column :offers, :last_balance_alert_time
  end
end
