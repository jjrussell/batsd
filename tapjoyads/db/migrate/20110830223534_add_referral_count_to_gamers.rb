class AddReferralCountToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :referral_count, :integer, :default => 0
  end

  def self.down
    remove_column :gamers, :referral_count
  end
end
