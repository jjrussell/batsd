class CreateEarningsAdjustments < ActiveRecord::Migration
  def self.up
    create_table :earnings_adjustments, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.integer :amount, :null => false
      t.string :notes
      t.timestamps
    end

    add_index :earnings_adjustments, :id, :unique => true
    add_index :earnings_adjustments, :partner_id

    add_column :monthly_accountings, :earnings_adjustments, :integer, :null => false
  end

  def self.down
    remove_column :monthly_accountings, :earnings_adjustments
    drop_table :earnings_adjustments
  end
end
