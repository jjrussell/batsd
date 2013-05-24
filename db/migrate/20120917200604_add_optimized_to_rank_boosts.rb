class AddOptimizedToRankBoosts < ActiveRecord::Migration
  def self.up
    add_column :rank_boosts, :optimized, :boolean, :default => false, :null => false
    add_index :rank_boosts, :optimized
  end

  def self.down
    remove_column :rank_boosts, :optimized, :boolean
  end
end
