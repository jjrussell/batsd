class AddNicknameToGamerProfile < ActiveRecord::Migration
  def self.up
    add_column :gamer_profiles, :name, :string
    add_column :gamer_profiles, :nickname, :string
    add_column :gamer_profiles, :postal_code, :string
    add_column :gamer_profiles, :favorite_category, :string
    add_column :gamer_profiles, :use_gravatar, :boolean, :default => false
  end

  def self.down
    remove_column :gamer_profiles, :name
    remove_column :gamer_profiles, :nickname
    remove_column :gamer_profiles, :postal_code
    remove_column :gamer_profiles, :favorite_category
    remove_column :gamer_profiles, :use_gravatar
  end
end
