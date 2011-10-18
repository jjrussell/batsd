class AddFbInfoToGamerProfiles < ActiveRecord::Migration
  def self.up
    add_column :gamer_profiles, :facebook_id, :string
    add_column :gamer_profiles, :fb_access_token, :string

    add_index :gamer_profiles, :facebook_id
  end

  def self.down
    remove_index :gamer_profiles, :facebook_id
        
    remove_column :gamer_profiles, :facebook_id
    remove_column :gamer_profiles, :fb_access_token
  end
end
