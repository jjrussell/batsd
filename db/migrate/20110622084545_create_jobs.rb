class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.boolean :active, :null => false, :default => false
      t.string :job_type, :null => false
      t.string :controller, :null => false
      t.string :action, :null => false, :default => 'index'
      t.string :frequency, :null => false
      t.integer :seconds, :null => false
      t.timestamps
    end

    add_index :jobs, :id, :unique => true
  end

  def self.down
    drop_table :jobs
  end
end
