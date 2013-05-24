class AddWhitelistOverriddenToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :whitelist_overridden, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :currencies, :whitelist_overridden
  end
end
