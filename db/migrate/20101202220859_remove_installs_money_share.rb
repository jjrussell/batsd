class RemoveInstallsMoneyShare < ActiveRecord::Migration
  def self.up
    remove_column :partners, :installs_money_share
    remove_column :currencies, :installs_money_share
  end

  def self.down
    add_column :partners, :installs_money_share, :decimal, :precision => 8, :scale => 6, :null => false, :default => 0.5
    add_column :currencies, :installs_money_share, :decimal, :precision => 8, :scale => 6, :null => false, :default => 0.5
  end
end
