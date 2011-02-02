class AddVariableNameToActionOffers < ActiveRecord::Migration
  def self.up
    add_column :action_offers, :variable_name, :string, :null => false
  end

  def self.down
    remove_column :action_offers, :variable_name
  end
end
