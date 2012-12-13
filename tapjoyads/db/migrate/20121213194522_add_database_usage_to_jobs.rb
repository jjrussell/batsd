class AddDatabaseUsageToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :uses_database, :boolean, :default => true
  end

  def self.down
    remove_column :jobs, :uses_database
  end
end
