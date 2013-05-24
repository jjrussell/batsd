class AddRotationFieldsToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :rotation_direction, :integer, :null => false, :default => 0
    add_column :apps, :rotation_time, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :apps, :rotation_direction
    remove_column :apps, :rotation_time
  end
end
