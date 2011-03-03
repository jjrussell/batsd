class AddStatsAggregationFieldsToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :next_daily_stats_aggregation_time, :datetime
    add_column :offers, :active, :boolean, :default => false
  end

  def self.down
    remove_column :offers, :next_daily_stats_aggregation_time
    remove_column :offers, :active
  end
end
