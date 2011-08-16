class AddConfirmationTokenIndexToGamers < ActiveRecord::Migration
  def self.up
    add_index :gamers, :confirmation_token, :unique => true
  end

  def self.down
    remove_index :gamers, :confirmation_token
  end
end
