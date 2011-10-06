class AddFbAccessTokenToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :fb_access_token, :string
  end

  def self.down
    remove_column :gamers, :fb_access_token
  end
end
