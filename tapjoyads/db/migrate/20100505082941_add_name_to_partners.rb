class AddNameToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :name, :string
  end

  def self.down
    remove_column :partners, :name
  end
end
