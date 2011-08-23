class AddCreateInvoiceToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :create_invoice, :boolean, :default => false
  end

  def self.down
    remove_column :orders, :create_invoice
  end
end
