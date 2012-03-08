class AddProtocolHandlerToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :protocol_handler, :string
  end

  def self.down
    remove_column :apps, :protocol_handler
  end
end
