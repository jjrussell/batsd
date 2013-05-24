class AddTjGamesOnlyToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :tj_games_only, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :tj_games_only
  end
end
