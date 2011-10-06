class AddFacebookIdToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :facebook_id, :string

    add_index :gamers, :facebook_id
  end

  def self.down
    remove_column :gamers, :facebook_id

    remove_index :gamers, :facebook_id
  end
end
