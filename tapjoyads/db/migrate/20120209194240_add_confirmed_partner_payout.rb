class AddConfirmedPartnerPayout < ActiveRecord::Migration
  def self.up
    add_column :partners, :payout_confirmed, :boolean, :default => false
  end

  def self.down
    remove_column :partners, :payout_confirmed
  end
end
