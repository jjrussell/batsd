class AddNextPayoutAmountToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :next_payout_amount, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :partners, :next_payout_amount
  end
end
