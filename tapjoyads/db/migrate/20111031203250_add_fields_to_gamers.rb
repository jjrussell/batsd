class AddFieldsToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :gender, :string
    add_column :gamers, :birthdate, :date
    add_column :gamers, :city, :string
    add_column :gamers, :country, :string
    add_column :gamers, :favorite_game, :string
    add_column :gamers, :name, :string
    add_column :gamers, :nickname, :string
    add_column :gamers, :postal_code, :string
    add_column :gamers, :favorite_category, :string
    add_column :gamers, :facebook_id, :string
    add_column :gamers, :fb_access_token, :string
    add_column :gamers, :referred_by, 'char(36) binary', :null => true
    add_column :gamers, :referral_count, :integer, :default => 0
    add_column :gamers, :use_gravatar, :boolean, :default => false
    add_column :gamers, :allow_marketing_emails, :boolean

    add_index :gamers, :referred_by
    add_index :gamers, :facebook_id
  end

  def self.down
    remove_index :gamers, :referred_by
    remove_index :gamers, :facebook_id

    remove_column :gamers, :allow_marketing_emails
    remove_column :gamers, :use_gravatar
    remove_column :gamers, :referral_count
    remove_column :gamers, :referred_by
    remove_column :gamers, :fb_access_token
    remove_column :gamers, :facebook_id
    remove_column :gamers, :favorite_category
    remove_column :gamers, :postal_code
    remove_column :gamers, :nickname
    remove_column :gamers, :name
    remove_column :gamers, :favorite_game
    remove_column :gamers, :country
    remove_column :gamers, :city
    remove_column :gamers, :birthdate
    remove_column :gamers, :gender
  end
end
