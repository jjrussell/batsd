class AddUncappedRatioToSpendShares < ActiveRecord::Migration
  def self.up
    add_column :spend_shares, :uncapped_ratio, :float, :null => false
  end

  def self.down
    remove_column :spend_shares, :uncapped_ratio
  end
end
