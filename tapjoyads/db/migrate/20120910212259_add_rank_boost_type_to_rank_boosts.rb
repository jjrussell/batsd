class AddRankBoostTypeToRankBoosts < ActiveRecord::Migration
  def self.up
    add_column :rank_boosts, :rank_boost_type, :string, :null => false
  end

  def self.down
    remove_column :rank_boosts, :rank_boost_type, :string
  end
end
