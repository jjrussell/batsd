class AddCountryToConversions < ActiveRecord::Migration
  def self.up
    add_column :conversions, :country, "char(2)"
  end

  def self.down
    remove_column :conversions, :country
  end
end
