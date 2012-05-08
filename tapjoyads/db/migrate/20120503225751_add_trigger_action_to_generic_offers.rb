class AddTriggerActionToGenericOffers < ActiveRecord::Migration
  def self.up
    add_column :generic_offers, :trigger_action, :string
  end

  def self.down
    remove_column :generic_offers, :trigger_action
  end
end
