class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.column :payment_txn_id, 'char(36) binary'
      t.column :refund_txn_id, 'char(36) binary'
      t.column :coupon_id, 'char(36) binary'
      t.integer :status, :null => false, :default => 1
      t.integer :payment_method, :null => false
      t.integer :amount, :null => false, :default => 0
      t.timestamps
    end

    add_index :orders, :id, :unique => true
    add_index :orders, :partner_id
    add_index :orders, :created_at
  end

  def self.down
    drop_table :orders
  end
end
