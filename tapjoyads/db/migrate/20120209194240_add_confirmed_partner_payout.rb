class AddConfirmedPartnerPayout < ActiveRecord::Migration
  def self.up
    add_column :partners, :confirmed_for_payout, :boolean, :default => false, :null => false
    add_column :partners, :payout_confirmation_notes, :string
  end

  def self.down
    remove_column :partners, :payout_confirmation_notes
    remove_column :partners, :confirmed_for_payout
  end
end
