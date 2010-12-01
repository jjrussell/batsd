class AddTransferBonusToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :transfer_bonus, :decimal, :precision => 8, :scale => 6, :null => false, :default => 0
  end

  def self.down
    remove_column :partners, :transfer_bonus
  end
end
