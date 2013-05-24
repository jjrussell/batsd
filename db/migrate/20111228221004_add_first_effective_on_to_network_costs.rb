class AddFirstEffectiveOnToNetworkCosts < ActiveRecord::Migration
  def self.up
    remove_index :network_costs, :created_at
    add_column :network_costs, :first_effective_on, :date, :null => false
  end

  def self.down
    remove_column :network_costs, :first_effective_on
    add_index :network_costs, :created_at
  end
end
