class AddTwitterInfoToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :twitter_id, :string
    add_column :gamers, :twitter_access_token, :string
    add_column :gamers, :twitter_access_secret, :string
    
    add_index :gamers, :twitter_id
  end

  def self.down
    remove_column :gamers, :twitter_id
    remove_column :gamers, :twitter_access_token
    remove_column :gamers, :twitter_access_secret
    
    remove_index :gamers, :twitter_id
  end
end
