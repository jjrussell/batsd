class AddPayoutFrequencyToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :payout_frequency, :string, :default => 'monthly', :null => false
  end

  def self.down
    remove_column :partners, :payout_frequency
  end
end
