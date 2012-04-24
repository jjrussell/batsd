class AddConcurrencyToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :max_concurrency, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :jobs, :max_concurrency
  end
end
