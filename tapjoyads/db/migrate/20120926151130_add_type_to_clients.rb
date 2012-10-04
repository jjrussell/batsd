class AddTypeToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :payment_type, :string
    add_column :clients, :payment_type_changed_at, :datetime
  end

  def self.down
    remove_column :clients, :payment_type
    remove_column :clients, :payment_type_changed_at
  end
end
