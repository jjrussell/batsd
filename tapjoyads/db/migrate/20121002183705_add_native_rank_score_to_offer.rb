class AddNativeRankScoreToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :native_rank_score, :decimal, :precision => 8, :scale => 6, :default => 0.0
  end

  def self.down
    remove_column :offers, :native_rank_score
  end
end
