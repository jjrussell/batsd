class AddBlockedToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :blocked, :boolean, :default => false
  end

  def self.down
    remove_column :gamers, :blocked
  end
end
