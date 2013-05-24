class MasterUserMigration < ActiveRecord::Migration
  def self.up
    # users
    drop_table :users
    create_table :users, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.string :username, :null => false
      t.string :email
      t.string :crypted_password
      t.string :password_salt
      t.string :persistence_token
      t.timestamps
    end
    add_index :users, :id, :unique => true
    add_index :users, :username, :unique => true

    # user_roles
    drop_table :user_roles
    create_table :user_roles, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.string :name, :null => false
      t.timestamps
    end
    add_index :user_roles, :id, :unique => true
    add_index :user_roles, :name, :unique => true

    # role_assignments
    drop_table :role_assignments
    create_table :role_assignments, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :user_id, 'char(36) binary', :null => false
      t.column :user_role_id, 'char(36) binary', :null => false
    end
    add_index :role_assignments, :id, :unique => true
    add_index :role_assignments, [ :user_id, :user_role_id ], :unique => true

    # partner_assignments
    create_table :partner_assignments, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :user_id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
    end
    add_index :partner_assignments, :id, :unique => true
    add_index :partner_assignments, [ :user_id, :partner_id ], :unique => true
    add_index :partner_assignments, :partner_id
  end

  def self.down
    drop_table :users
    drop_table :user_roles
    drop_table :role_assignments
    drop_table :partner_assignments
  end
end
