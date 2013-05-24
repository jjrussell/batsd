class RemoveTjGamesOnlyColumnFromOffers < ActiveRecord::Migration
  def self.up
    remove_column :offers, :tj_games_only
  end

  def self.down
    add_column :offers, :tj_games_only, :boolean, :null => false, :default => false
  end
end
