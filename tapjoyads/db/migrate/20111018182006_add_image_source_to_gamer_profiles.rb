class AddImageSourceToGamerProfiles < ActiveRecord::Migration
  def self.up
    add_column :gamer_profiles, :image_source, :string, :default => 'gravatar'
  end

  def self.down
    remove_column :gamer_profiles, :image_source
  end
end
