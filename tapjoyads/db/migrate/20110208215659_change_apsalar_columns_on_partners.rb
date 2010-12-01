class ChangeApsalarColumnsOnPartners < ActiveRecord::Migration
  def self.up
    remove_column :partners, :apsalar_password
    add_column :partners, :apsalar_url, :text
  end

  def self.down
    remove_column :partners, :apsalar_url
    add_column :partners, :apsalar_password, :string
  end
end
