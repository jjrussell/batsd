class AddRegionToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :region, :text
  end

  def self.down
    remove_column :offers, :region
  end
end

