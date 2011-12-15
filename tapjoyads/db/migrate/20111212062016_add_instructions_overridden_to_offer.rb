class AddInstructionsOverriddenToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :instructions_overridden, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :instructions_overridden
  end
end
