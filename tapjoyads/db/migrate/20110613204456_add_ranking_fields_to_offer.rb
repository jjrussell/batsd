class AddRankingFieldsToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :normal_conversion_rate, :float, :default => 0, :null => false
    add_column :offers, :normal_price, :float, :default => 0, :null => false
    add_column :offers, :normal_avg_revenue, :float, :default => 0, :null => false
    add_column :offers, :normal_bid, :float, :default => 0, :null => false
    add_column :offers, :over_threshold, :integer, :default => 0, :null => false
    rename_column :currency_groups, :conversion_rate, :normal_conversion_rate
    rename_column :currency_groups, :price, :normal_price
    rename_column :currency_groups, :avg_revenue, :normal_avg_revenue
    rename_column :currency_groups, :bid, :normal_bid
    add_column :currency_groups, :rank_boost, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :offers, :normal_conversion_rate
    remove_column :offers, :normal_price
    remove_column :offers, :normal_avg_revenue
    remove_column :offers, :normal_bid
    remove_column :offers, :over_threshold
    rename_column :currency_groups, :normal_conversion_rate, :conversion_rate
    rename_column :currency_groups, :normal_price, :price
    rename_column :currency_groups, :normal_avg_revenue, :avg_revenue
    rename_column :currency_groups, :normal_bid, :bid
    remove_column :currency_groups, :rank_boost
  end
end
