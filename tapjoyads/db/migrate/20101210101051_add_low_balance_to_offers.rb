class AddLowBalanceToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :low_balance, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :low_balance
  end
end
