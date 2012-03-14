class CreateWfhs < ActiveRecord::Migration
  def self.up
    add_column :employees, :desk_location, :string, :unique => true
    add_column :employees, :department, :string

    create_table :wfhs, :id => false do |t|
      t.guid   :id,          :null => false
      t.guid   :employee_id, :null => false
      t.string :category,    :null => false
      t.string :description
      t.date   :start_date,   :null => false
      t.date   :end_date,     :null => false

      t.timestamps
    end

    add_index :wfhs, :id, :unique => true
    add_index :wfhs, :employee_id
    add_index :wfhs, :start_date
    add_index :wfhs, :end_date
  end

  def self.down
    drop_table :wfhs

    remove_column :employees, :department
    remove_column :employees, :desk_location
  end
end
