class AddCarriersToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :carriers, :char(36), :null => false, :default => ''
  end

  def self.down
    remove_column :offers, :carriers
  end
end
