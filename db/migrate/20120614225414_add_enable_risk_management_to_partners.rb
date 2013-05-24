class AddEnableRiskManagementToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :enable_risk_management, :bool, :null => false, :default => false
  end

  def self.down
    remove_column :partners, :enable_risk_management
  end
end
