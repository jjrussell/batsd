class AddOfferFlagToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :discount_all_offer_types, :bool, :null => false, :default => false
  end

  def self.down
    remove_column :partners, :discount_all_offer_types
  end
end
