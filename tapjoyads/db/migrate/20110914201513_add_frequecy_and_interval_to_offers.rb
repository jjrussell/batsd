class AddFrequecyAndIntervalToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :frequency, :integer, :null => false, :default => 0
    add_column :offers, :interval, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :offers, :frequency
    remove_column :offers, :interval
  end
end
