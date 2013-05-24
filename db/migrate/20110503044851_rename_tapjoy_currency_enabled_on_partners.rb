class RenameTapjoyCurrencyEnabledOnPartners < ActiveRecord::Migration
  def self.up
    rename_column :partners, :tapjoy_currency_enabled, :approved_publisher
  end

  def self.down
    rename_column :partners, :approved_publisher, :tapjoy_currency_enabled
  end
end
