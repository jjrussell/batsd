class ChangeGamers < ActiveRecord::Migration
  def self.up
    drop_table :gamers

    create_table :gamers, :id => false do |t|
      t.guid :id, :null => false
      t.string :email, :null => false
      t.string :crypted_password
      t.string :password_salt
      t.string :persistence_token
      t.string :perishable_token
      t.string :referrer
      t.datetime :current_login_at
      t.datetime :last_login_at
      t.datetime :confirmed_at
      t.timestamps
    end

    add_index :gamers, :id, :unique => true
    add_index :gamers, :email, :unique => true
    add_index :gamers, :persistence_token
    add_index :gamers, :perishable_token
  end

  def self.down
    drop_table :gamers

    create_table :gamers, :id => false do |t|
      t.guid :id, :null => false
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
end
