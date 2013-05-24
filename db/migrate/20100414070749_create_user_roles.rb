class CreateUserRoles < ActiveRecord::Migration
  def self.up
    create_table :user_roles do |t|
      t.string :name, :null => false
      t.timestamps
    end

    add_index :user_roles, :name, :unique => true

    UserRole.create(:name => 'admin')
    UserRole.create(:name => 'offerpal')
  end

  def self.down
    drop_table :user_roles
  end
end
