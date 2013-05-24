class CreateNetworkCosts < ActiveRecord::Migration
  def self.up
    create_table :network_costs, :id => false do |t|
      t.guid    :id,     :null => false
      t.integer :amount, :null => false, :default => 0
      t.text    :notes
      t.timestamps
    end
    add_index :network_costs, :id , :unique => true
    add_index :network_costs, :created_at
  end

  def self.down
    drop_table :network_costs
  end
end
