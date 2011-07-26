class AddFreshbooksFieldsToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :invoice_id, :integer
    add_column :orders, :description, :string
    add_column :orders, :note_to_client, :string

    add_index :orders, :invoice_id, :unique => true
  end

  def self.down
    remove_column :orders, :invoice_id
    remove_column :orders, :description
    remove_column :orders, :note_to_client
  end
end
