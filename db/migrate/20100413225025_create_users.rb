class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :partner_id, 'char(36) binary', :null => false
      t.string :username
      t.string :email
      t.string :crypted_password
      t.string :password_salt
      t.string :persistence_token
      t.timestamps
    end

    add_index :users, :partner_id
  end

  def self.down
    drop_table :users
  end
end
