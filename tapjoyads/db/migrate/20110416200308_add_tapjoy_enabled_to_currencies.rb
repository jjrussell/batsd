class AddTapjoyEnabledToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :tapjoy_enabled, :boolean, :null => false, :default => false
    Currency.connection.execute("UPDATE currencies SET tapjoy_enabled = true")
  end

  def self.down
    remove_column :currencies, :tapjoy_enabled
  end
end
