class AddTapjoyEnabledToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :tapjoy_enabled, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :currencies, :tapjoy_enabled
  end
end
