class AddMinimumOsVersion < ActiveRecord::Migration
  def self.up
    add_column :offers, :min_os_version, :string, :default => "", :null => false
  end

  def self.down
    remove_column :offers, :min_os_version
  end
end
