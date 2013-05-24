class AddDirectPayFields < ActiveRecord::Migration
  def self.up
    add_column :partners, :direct_pay_share, :decimal, :precision => 8, :scale => 6, :null => false, :default => 1.0
    add_column :currencies, :direct_pay_share, :decimal, :precision => 8, :scale => 6, :null => false, :default => 1.0
    add_column :offers, :direct_pay, :string
  end

  def self.down
    remove_column :partners, :direct_pay_share
    remove_column :currencies, :direct_pay_share
    remove_column :offers, :direct_pay
  end
end
