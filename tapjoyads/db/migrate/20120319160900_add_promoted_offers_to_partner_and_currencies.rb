class AddPromotedOffersToPartnerAndCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :promoted_offers, :text, :null => false, :default => ''
    add_column :partners, :promoted_offers, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :currencies, :promoted_offers
    remove_column :partners, :promoted_offers
  end
end
