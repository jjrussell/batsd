class AddClientIdToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :client_id, 'char(36) binary'
  end

  def self.down
    remove_column :partners, :client_id
  end
end
