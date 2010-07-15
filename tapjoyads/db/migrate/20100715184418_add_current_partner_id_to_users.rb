class AddCurrentPartnerIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :current_partner_id, 'char(36) binary'
  end

  def self.down
    remove_column :users, :current_partner_id
  end
end
