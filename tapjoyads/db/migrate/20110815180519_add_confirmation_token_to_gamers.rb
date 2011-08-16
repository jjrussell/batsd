class AddConfirmationTokenToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :confirmation_token, :string, :default => "", :null => false
  end

  def self.down
    remove_column :gamers, :confirmation_token
  end
end
