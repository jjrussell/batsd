class AddNegotiatedRevShareToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :negotiated_rev_share, :boolean
  end

  def self.down
    remove_column :partners, :negotiated_rev_share
  end
end
