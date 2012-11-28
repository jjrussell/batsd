class AddMessageToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :message, :text
    add_column :currencies, :message_enabled, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :currencies, :message
    remove_column :currencies, :message_enabled
  end
end
