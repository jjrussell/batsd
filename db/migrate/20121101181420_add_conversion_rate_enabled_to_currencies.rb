class AddConversionRateEnabledToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :conversion_rate_enabled, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :currencies, :conversion_rate_enabled
  end
end
