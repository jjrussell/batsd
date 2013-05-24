class AddAuthNetCimIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :auth_net_cim_id, :string
  end

  def self.down
    remove_column :users, :auth_net_cim_id
  end
end
