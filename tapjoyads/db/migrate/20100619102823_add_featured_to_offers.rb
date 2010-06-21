class AddFeaturedToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :featured, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :featured
  end
end
