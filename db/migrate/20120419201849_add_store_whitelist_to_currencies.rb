class AddStoreWhitelistToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :store_whitelist, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :currencies, :store_whitelist
  end
end
