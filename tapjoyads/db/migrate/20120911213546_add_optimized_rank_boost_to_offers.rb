class AddOptimizedRankBoostToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :optimized_rank_boost, :integer, :default => 0, :null => false
    add_index :offers, :optimized_rank_boost
  end

  def self.down
    add_column :offers, :optimized_rank_boost
  end
end
