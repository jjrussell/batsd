class AddFbUrlToGenericOffer < ActiveRecord::Migration
  def self.up
    add_column :generic_offers, :fb_url, :string
  end

  def self.down
    remove_column :generic_offers, :fb_url
  end
end
