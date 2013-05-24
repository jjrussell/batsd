class CreatePayouts < ActiveRecord::Migration
  def self.up
    create_table :payouts, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.integer :amount, :null => false, :default => 0
      t.integer :month, :null => false
      t.integer :year, :null => false
      t.timestamps
    end

    add_index :payouts, :id, :unique => true
  end

  def self.down
    drop_table :payouts
  end
end
