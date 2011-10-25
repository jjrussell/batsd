class AddImageSourceToGamerProfiles < ActiveRecord::Migration
  def self.up
    add_column :gamer_profiles, :image_source, :string, :default => 'gravatar'
    remove_column :gamer_profiles, :use_gravatar
  end

  def self.down
    remove_column :gamer_profiles, :image_source
    add_column :gamer_profiles, :use_gravatar, :boolean, :default => false
  end
end
