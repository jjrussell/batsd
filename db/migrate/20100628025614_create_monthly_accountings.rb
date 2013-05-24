class CreateMonthlyAccountings < ActiveRecord::Migration
  def self.up
    create_table :monthly_accountings, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.integer :month, :null => false
      t.integer :year, :null => false
      t.integer :beginning_balance, :null => false
      t.integer :ending_balance, :null => false
      t.integer :website_orders, :null => false
      t.integer :invoiced_orders, :null => false
      t.integer :marketing_orders, :null => false
      t.integer :transfer_orders, :null => false
      t.integer :spend, :null => false
      t.integer :beginning_pending_earnings, :null => false
      t.integer :ending_pending_earnings, :null => false
      t.integer :payment_payouts, :null => false
      t.integer :transfer_payouts, :null => false
      t.integer :earnings, :null => false
      t.timestamps
    end

    add_index :monthly_accountings, :id, :unique => true
    add_index :monthly_accountings, [:partner_id, :month, :year], :unique => true
    add_index :monthly_accountings, [:month, :year]
    add_index :monthly_accountings, :partner_id

  end

  def self.down
    drop_table :monthly_accountings
  end

end
