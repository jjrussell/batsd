class AddReferredByToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :referred_by, 'char(36) binary', :null => true
    add_index :gamers, :referred_by
  end

  def self.down
    remove_index :gamers, :referred_by
    remove_column :gamers, :referred_by
  end
end
