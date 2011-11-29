class AddNegotiatedRevShareEndToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :negotiated_rev_share_end, :date
  end

  def self.down
    remove_column :partners, :negotiated_rev_share_end
  end
end
