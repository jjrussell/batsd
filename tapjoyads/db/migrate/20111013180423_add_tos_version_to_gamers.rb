class AddTosVersionToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :accepted_tos_version, :integer, :default => 0
    add_column :gamer_profiles, :allow_marketing_emails, :boolean, :default => true
    remove_column :gamer_profiles, :first_name
    remove_column :gamer_profiles, :last_name
  end

  def self.down
    remove_column :gamers, :accepted_tos_version
    remove_column :gamer_profiles, :allow_marketing_emails
    add_column :gamer_profiles, :first_name, :string
    add_column :gamer_profiles, :last_name, :string
  end
end
