class AddCountryToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :country, :string
  end

  def self.down
    drop_column :partners, :country
  end
end
