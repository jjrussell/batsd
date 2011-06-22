class AddDisplayOrderToEmployee < ActiveRecord::Migration
  def self.up
    add_column :employees, :display_order, :integer
  end

  def self.down
    remove_column :employees, :display_order
  end
end
