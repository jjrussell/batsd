class RemoveOffersMoneyShareFromCurrencies < ActiveRecord::Migration
  def self.up
    remove_column :currencies, :offers_money_share
  end

  def self.down
    add_column :currencies, :offers_money_share, :decimal, :percision => 8, :scale => 6, :null => false, :default => 0.85
  end
end
