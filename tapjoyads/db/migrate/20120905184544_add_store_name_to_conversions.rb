class AddStoreNameToConversions < ActiveRecord::Migration
  def self.up
    add_column :conversions, :store_name, :string
  end

  def self.down
    remove_column :conversions, :store_name
  end
end
