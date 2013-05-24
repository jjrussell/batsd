class AddCityToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :office, :string
  end

  def self.down
    remove_column :employees, :office
  end
end
