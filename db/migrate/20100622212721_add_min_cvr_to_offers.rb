class AddMinCvrToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :min_conversion_rate, :decimal, :precision => 8, :scale => 6
  end

  def self.down
    remove_column :offers, :min_conversion_rate
  end
end
