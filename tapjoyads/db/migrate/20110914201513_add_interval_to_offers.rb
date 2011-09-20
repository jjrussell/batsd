class AddIntervalToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :interval, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :offers, :interval
  end
end
