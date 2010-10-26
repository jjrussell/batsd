class ChangeDefaultInstallsRevShare < ActiveRecord::Migration
  def self.up
    change_column_default :currencies, :installs_money_share, 0.5
  end

  def self.down
    change_column_default :currencies, :installs_money_share, 0.7
  end
end
