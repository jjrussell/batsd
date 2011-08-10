class AddEmployeeToUserRoles < ActiveRecord::Migration
  def self.up
    add_column :user_roles, :employee, :boolean
  end

  def self.down
    remove_column :user_roles, :employee
  end
end
