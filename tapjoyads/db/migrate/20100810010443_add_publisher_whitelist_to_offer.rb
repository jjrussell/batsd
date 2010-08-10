class AddPublisherWhitelistToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :publisher_app_whitelist, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :offers, :publisher_app_whitelist
  end
end
