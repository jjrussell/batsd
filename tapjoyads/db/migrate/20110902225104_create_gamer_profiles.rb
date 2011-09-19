class CreateGamerProfiles < ActiveRecord::Migration
  def self.up
    create_table :gamer_profiles, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :gamer_id, 'char(36) binary', :null => false
      t.string :last_name
      t.string :first_name
      t.string :gender
      t.date :birthdate
      t.string :city
      t.string :country
      t.string :favorite_game
      t.timestamps
    end

    add_index :gamer_profiles, :id, :unique => true
    add_index :gamer_profiles, :gamer_id, :unique => true
  end

  def self.down
    drop_table :gamer_profiles
  end
end
