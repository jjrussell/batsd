class AddRankBoostTypeToRankBoosts < ActiveRecord::Migration
  def self.up
    add_column :rank_boosts, :rank_boost_type, :text, :null => false
  end

  def self.down
    remove_column :rank_boosts, :rank_boost_type, :text
  end
end
