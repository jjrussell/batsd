class CreateEmployees < ActiveRecord::Migration
  def self.up
    create_table :employees, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.boolean :active, :null => false, :default => true
      t.string :first_name, :null => false
      t.string :last_name, :null => false
      t.string :title, :null => false
      t.string :email, :null => false
      t.string :superpower
      t.string :current_games
      t.string :weapon
      t.text   :biography

      t.timestamps
    end

    add_index :employees, :id, :unique => true
    add_index :employees, :email, :unique => true
  end

  def self.down
    drop_table :employees
  end
end
