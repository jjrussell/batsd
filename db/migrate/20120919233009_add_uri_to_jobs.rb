class AddUriToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :uri, :string
  end

  def self.down
    remove_column :jobs, :uri
  end
end
