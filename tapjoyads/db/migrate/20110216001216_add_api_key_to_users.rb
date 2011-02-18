class AddApiKeyToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :api_key, :string, :null => false
  end

  def self.down
    remove_column :users, :api_key
  end
end
