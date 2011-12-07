class AddNegotiatedRevShareEndsOnAndAcceptedNegotiatedTosToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :negotiated_rev_share_ends_on, :date
    add_column :partners, :accepted_negotiated_tos, :boolean, :default => false
  end

  def self.down
    remove_column :partners, :negotiated_rev_share_ends_on
    remove_column :partners, :accepted_negotiated_tos
  end
end

