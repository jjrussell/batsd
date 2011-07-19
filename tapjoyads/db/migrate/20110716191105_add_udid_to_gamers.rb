class AddUdidToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :udid, :string
  end

  def self.down
    remove_column :gamers, :udid
  end
end
