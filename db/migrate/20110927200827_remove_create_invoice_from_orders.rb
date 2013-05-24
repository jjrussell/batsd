class RemoveCreateInvoiceFromOrders < ActiveRecord::Migration
  def self.up
    remove_column :orders, :create_invoice
  end

  def self.down
    add_column :orders, :create_invoice, :boolean, :default => false
  end
end
