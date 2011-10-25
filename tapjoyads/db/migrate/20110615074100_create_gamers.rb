class CreateGamers < ActiveRecord::Migration
  def self.up
    create_table :gamers, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.string :username, :null => false
      t.string :email
      t.string :crypted_password
      t.string :password_salt
      t.string :persistence_token
      t.string :perishable_token
      t.string :referrer
      t.datetime :current_login_at
      t.datetime :last_login_at
      t.timestamps
    end

    add_index :gamers, :id, :unique => true
    add_index :gamers, :username, :unique => true
    add_index :gamers, :persistence_token
    add_index :gamers, :perishable_token
  end

  def self.down
    drop_table :gamers
  end
end
