class ReMigrateAddUseServerWhitelistToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :use_server_whitelist, :bool, :null => false, :default => false
  end

  def self.down
    remove_column :partners, :use_server_whitelist
  end
end
