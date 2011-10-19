class AddTwitterInfoToGamerProfiles < ActiveRecord::Migration
  def self.up
    add_column :gamer_profiles, :twitter_id, :string
    add_column :gamer_profiles, :twitter_access_token, :string
    add_column :gamer_profiles, :twitter_access_secret, :string
    
    add_index :gamer_profiles, :twitter_id
  end

  def self.down
    remove_column :gamer_profiles, :twitter_id
    remove_column :gamer_profiles, :twitter_access_token
    remove_column :gamer_profiles, :twitter_access_secret
    
    remove_index :gamer_profiles, :twitter_id
  end
end
