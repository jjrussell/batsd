class AddTapjoyEnabledToPartnersAndCurrencies < ActiveRecord::Migration
  def self.up
    add_column :partners, :tapjoy_currency_enabled, :boolean, :null => false, :default => false
    add_column :currencies, :tapjoy_enabled, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :currencies, :tapjoy_enabled
    remove_column :partners, :tapjoy_currency_enabled
  end
end
