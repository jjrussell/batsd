class AddRateFilterOverrideToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :rate_filter_override, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :offers, :rate_filter_override
  end
end
