class AddPartnerIdToCurrency < ActiveRecord::Migration
  def self.up
    add_column :currencies, :partner_id, 'char(36) binary', :null => false
  end

  def self.down
    remove_column :currencies, :partner_id
  end
end
