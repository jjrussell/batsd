class RemoveOrdinalFromOffers < ActiveRecord::Migration
  def self.up
    remove_column :offers, :ordinal
  end

  def self.down
    add_column :offers, :ordinal, :integer, :null => false, :default => 500
  end
end
