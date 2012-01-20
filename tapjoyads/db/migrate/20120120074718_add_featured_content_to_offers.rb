class AddFeaturedContentToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :fc_tracking, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :fc_tracking
  end
end
