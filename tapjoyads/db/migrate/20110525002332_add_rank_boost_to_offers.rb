class AddRankBoostToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :rank_boost, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :offers, :rank_boost
  end
end
