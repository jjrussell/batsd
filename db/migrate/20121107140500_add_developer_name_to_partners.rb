class AddDeveloperNameToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :developer_name, :string
  end

  def self.down
    remove_column :partners, :developer_name
  end
end
