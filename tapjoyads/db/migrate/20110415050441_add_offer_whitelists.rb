class AddOfferWhitelists < ActiveRecord::Migration
  def self.up
    add_column :partners, :offer_whitelist, :text, :null => false, :default => ''
    add_column :partners, :use_whitelist, :boolean, :default => false, :null => false

    add_column :currencies, :offer_whitelist, :text, :null => false, :default => ''
    add_column :currencies, :use_whitelist, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :partners, :offer_whitelist
    remove_column :partners, :use_whitelist

    remove_column :currencies, :offer_whitelist
    remove_column :currencies, :use_whitelist
  end
end
