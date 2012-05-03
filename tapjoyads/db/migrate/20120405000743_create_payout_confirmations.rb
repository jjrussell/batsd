class CreatePayoutConfirmations < ActiveRecord::Migration
  def self.up
    add_column :partners, :payout_threshold, :integer, :null => false, :default => 50_000_00
    add_column :partners, :payout_info_confirmation, :boolean, :null => false, :default => false
    add_column :partners, :payout_threshold_confirmation, :boolean, :null => false, :default => false

    Partner.find_each do | partner|
      partner.payout_threshold_confirmation = partner.confirmed_for_payout || partner.payout_confirmation_notes.nil? || !partner.payout_confirmation_notes =~ /^SYSTEM:.*threshold.*$/
      partner.payout_info_confirmation = partner.confirmed_for_payout || !partner.payout_confirmation_notes.nil? || !partner.payout_confirmation_notes =~ /^SYSTEM:.*changed.*$/
      partner.save!
    end

    remove_column :partners, :confirmed_for_payout
    remove_column :partners, :payout_confirmation_notes
  end

  def self.down
    add_column :partners, :payout_confirmation_notes, :string
    add_column :partners, :confirmed_for_payout, :boolean, :null => false, :default => false

    Partner.find_each do | partner|
      partner.confirmed_for_payout = partner.payout_threshold_confirmation && partner.payout_info_confirmation
      partner.save!
    end
    remove_column :partners, :payout_threshold
    remove_column :partners, :payout_info_confirmation
    remove_column :partners, :payout_threshold_confirmation
  end
end
