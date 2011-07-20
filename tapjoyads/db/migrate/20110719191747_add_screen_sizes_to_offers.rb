class AddScreenSizesToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :screen_sizes, :text
  end

  def self.down
    remove_column :offers, :screen_sizes
  end
end
