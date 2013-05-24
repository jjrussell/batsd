class CreatePartners < ActiveRecord::Migration
  def self.up
    create_table :partners, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.string :contact_name
      t.string :contact_phone
      t.integer :balance, :null => false, :default => 0
      t.integer :pending_earnings, :null => false, :default => 0
      t.timestamps
    end

    add_index :partners, :id, :unique => true
  end

  def self.down
    drop_table :partners
  end
end
