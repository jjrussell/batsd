class AddCitiesToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :cities, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :offers, :cities
  end
end
