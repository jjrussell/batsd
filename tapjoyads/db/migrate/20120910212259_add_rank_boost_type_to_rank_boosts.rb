class AddRankBoostTypeToRankBoosts < ActiveRecord::Migration
  def self.up
    add_column :rank_boosts, :rank_boost_type, :integer, :default => RankBoost::NATIVE_VALUE, :null => false
  end

  def self.down
    remove_column :rank_boosts, :rank_boost_type, :integer
  end
end
