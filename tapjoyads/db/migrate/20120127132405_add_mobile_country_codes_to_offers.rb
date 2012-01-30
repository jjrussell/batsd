class AddMobileCountryCodesToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :mobile_country_codes, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :offers, :mobile_country_codes
  end
end