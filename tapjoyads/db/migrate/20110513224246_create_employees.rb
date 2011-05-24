class CreateEmployees < ActiveRecord::Migration
  def self.up
    create_table :employees do |t|
      t.boolean :active, :null => false, :default => true
      t.string :first_name, :null => false
      t.string :middle_name
      t.string :last_name, :null => false
      t.string :title, :null => false
      t.string :department
      t.string :email, :null => false
      t.text   :comments
      t.binary :photo, :limit => 1.megabyte
      t.string :photo_content_type

      t.timestamps
    end
  end

  def self.down
    drop_table :employees
  end
end
