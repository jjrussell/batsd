class AddApsalarLoginToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :apsalar_username, :string
    add_column :partners, :apsalar_password, :string
    add_column :partners, :apsalar_api_secret, :string
  end

  def self.down
    remove_column :partners, :apsalar_username
    remove_column :partners, :apsalar_password
    remove_column :partners, :apsalar_api_secret
  end
end
