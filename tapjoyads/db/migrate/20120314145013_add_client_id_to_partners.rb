class AddClientIdToPartners < ActiveRecord::Migration
  def self.up
    add_guid_column :partners, :client_id
  end

  def self.down
    remove_column :partners, :client_id
  end
end
