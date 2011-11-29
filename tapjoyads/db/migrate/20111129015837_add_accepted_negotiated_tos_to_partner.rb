class AddAcceptedNegotiatedTosToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :accepted_negotiated_tos, :boolean
  end

  def self.down
    remove_column :partners, :accepted_negotiated_tos
  end
end
