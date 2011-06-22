class AddExternalPublisherToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :external_publisher, :boolean, :null => false, :default => false
    add_column :currencies, :potential_external_publisher, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :currencies, :external_publisher
    remove_column :currencies, :potential_external_publisher
  end
end
