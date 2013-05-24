class AddReferralInfoToGamerProfiles < ActiveRecord::Migration
  def self.up
    add_column :gamer_profiles, :referred_by, 'char(36) binary', :null => true
    add_column :gamer_profiles, :referral_count, :integer, :default => 0

    add_index :gamer_profiles, :referred_by
  end

  def self.down
    remove_index :gamer_profiles, :referred_by

    remove_column :gamer_profiles, :referred_by
    remove_column :gamer_profiles, :referral_count
  end
end
