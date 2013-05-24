class AddOrdinalToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :ordinal, :integer, :null => false, :default => 500
  end

  def self.down
    remove_column :currencies, :ordinal
  end
end
