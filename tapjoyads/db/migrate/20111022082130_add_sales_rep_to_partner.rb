class AddSalesRepToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :sales_rep_id, 'char(36) binary'
  end

  def self.down
    remove_column :partners, :sales_rep
  end
end
