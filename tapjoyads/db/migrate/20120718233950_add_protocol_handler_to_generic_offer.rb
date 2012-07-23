class AddProtocolHandlerToGenericOffer < ActiveRecord::Migration
  def self.up
    add_column :generic_offers, :protocol_handler, :string
  end

  def self.down
    remove_column :protocol_handler, :trigger_action
  end
end
