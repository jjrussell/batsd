class AddRateFieldsToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :conversion_rate, :decimal, :precision => 8, :scale => 6, :null => false, :default => 0
    add_column :offers, :show_rate, :decimal, :precision => 8, :scale => 6, :null => false, :default => 1.0
  end

  def self.down
    remove_column :offers, :conversion_rate
    remove_column :offers, :show_rate
  end
end
