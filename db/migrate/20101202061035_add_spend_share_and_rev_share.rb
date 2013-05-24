class AddSpendShareAndRevShare < ActiveRecord::Migration
  def self.up
    add_column :partners, :rev_share, :decimal, :precision => 8, :scale => 6, :null => false, :default => 0.5
    add_column :currencies, :spend_share, :decimal, :precision => 8, :scale => 6, :null => false, :default => 0.5
  end

  def self.down
    remove_column :partners, :rev_share
    remove_column :currencies, :spend_share
  end
end
