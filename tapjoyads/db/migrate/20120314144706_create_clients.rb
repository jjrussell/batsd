class CreateClients < ActiveRecord::Migration
  def self.up
    create_table :clients, :id => false do |t|
      t.guid   :id, :null => false
      t.string :name, :null => false
      t.timestamps
    end

    add_index :clients, :id, :unique => true
    add_index :clients, :name

  end

  def self.down
    drop_table :clients
  end
end
