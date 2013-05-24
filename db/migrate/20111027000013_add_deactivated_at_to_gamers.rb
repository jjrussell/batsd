class AddDeactivatedAtToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :deactivated_at, :timestamp
    add_index :gamers, :deactivated_at
  end

  def self.down
    remove_index :gamers, :deactivated_at
    remove_column :gamers, :deactivated_at
  end
end
