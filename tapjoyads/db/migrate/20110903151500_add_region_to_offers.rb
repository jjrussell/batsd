class AddRegionToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :regions, :text
  end

  def self.down
    remove_column :offers, :regions
  end
end

