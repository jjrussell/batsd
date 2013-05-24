class AddAppstatsFieldsToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :next_stats_aggregation_time, :datetime
    add_column :offers, :last_stats_aggregation_time, :datetime
    add_column :offers, :last_daily_stats_aggregation_time, :datetime
    add_column :offers, :stats_aggregation_interval, :integer
  end

  def self.down
    remove_column :offers, :next_stats_aggregation_time
    remove_column :offers, :last_stats_aggregation_time
    remove_column :offers, :last_daily_stats_aggregation_time
    remove_column :offers, :stats_aggregation_interval
  end
end
