class CreateConsoleSecurityTables < ActiveRecord::Migration
  def self.up
    # console_authentications
    create_table :console_authentications, :id => false do |t|
      t.guid :id,         :null => false
      t.string :provider, :null => false
      t.string :uid,      :null => false
      t.guid :user_id,    :null => false
      t.text :info

      t.timestamps
    end

    add_index :console_authentications, :id, :unique => true

    # console_permissions
    create_table :console_permissions, :id => false do |t|
      t.guid :id,            :null => false
      t.guid :group_id,      :null => false
      t.string :action,      :null => false
      t.string :target,      :null => false
      t.string :application, :null => false

      t.timestamps
    end

    add_index :console_permissions, :id, :unique => true
    add_index :console_permissions, :group_id
    add_index :console_permissions, :application

    # console_security_permits
    create_table :console_security_permits, :id => false do |t|
      t.guid :id,            :null => false
      t.string :name,        :null => false
      t.string :application, :null => false

      t.timestamps
    end

    add_index :console_security_permits, :id, :unique => true
    add_index :console_security_permits, :application

    # console_security_restrictions
    create_table :console_security_restrictions, :id => false do |t|
      t.guid :id,            :null => false
      t.string :name,        :null => false
      t.string :application, :null => false

      t.timestamps
    end

    add_index :console_security_restrictions, :id, :unique => true
    add_index :console_security_restrictions, :application

    # console_roles
    create_table :console_roles, :id => false do |t|
      t.guid :id,            :null => false
      t.string :name,        :null => false
      t.boolean :publicly_visible
      t.string :application, :null => false

      t.timestamps
    end

    add_index :console_roles, :id, :unique => true
    add_index :console_roles, :application

    # console_roles_console_security_permits join table
    create_table :console_roles_console_security_permits, :id => false do |t|
      t.guid :console_security_permit_id, :null => false
      t.guid :console_role_id,            :null => false
    end

    add_index :console_roles_console_security_permits, :console_security_permit_id, :name => 'index_console_roles_console_security_permits_on_permit_id'
    add_index :console_roles_console_security_permits, :console_role_id,            :name => 'index_console_roles_console_security_permits_on_role_id'

    # console_roles_console_security_restrictions join table
    create_table :console_roles_console_security_restrictions, :id => false do |t|
      t.guid :console_security_restriction_id, :null => false
      t.guid :console_role_id,                 :null => false
    end

    add_index :console_roles_console_security_restrictions, :console_security_restriction_id, :name => 'index_console_roles_console_security_restrictions_on_restr_id'
    add_index :console_roles_console_security_restrictions, :console_role_id,                 :name => 'index_console_roles_console_security_restrictions_on_role_id'
  end

  def self.down
    drop_table :console_authentications
    drop_table :console_permissions
    drop_table :console_security_permits
    drop_table :console_security_restrictions
    drop_table :console_roles
    drop_table :console_roles_console_security_permits
    drop_table :console_roles_console_security_restrictions
  end
end
