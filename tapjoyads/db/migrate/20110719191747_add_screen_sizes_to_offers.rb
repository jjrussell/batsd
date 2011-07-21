class AddScreenSizesToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :screen_layout_sizes, :text, :null => false
  end

  def self.down
    remove_column :offers, :screen_layout_sizes
  end
end
