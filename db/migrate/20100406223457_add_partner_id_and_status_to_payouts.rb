class AddPartnerIdAndStatusToPayouts < ActiveRecord::Migration
  def self.up
    add_column :payouts, :partner_id, 'char(36) binary', :null => false
    add_column :payouts, :status, :integer, :null => false
    add_index :payouts, :partner_id
  end

  def self.down
    remove_index :payouts, :column => :partner_id
    remove_column :payouts, :partner_id
    remove_column :payouts, :status
  end
end
