class AddCarriersToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :carriers, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :offers, :carriers
  end
end
