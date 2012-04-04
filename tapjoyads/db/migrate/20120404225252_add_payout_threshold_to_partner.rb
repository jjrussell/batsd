class AddPayoutThresholdToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :payout_threshold, :integer, :null => false, :default => 50_000_00
  end

  def self.down
    remove_column :partners, :payout_threshold
  end
end
