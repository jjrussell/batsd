class CreateAppMetadatas < ActiveRecord::Migration
  def self.up
    # app_metadatas
    create_table :app_metadatas, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.string :name
      t.text :description
      t.integer :price, :default => 0
      t.string :store_name, :null => false
      t.string :store_id, :null => false
      t.integer :age_rating
      t.integer :file_size_bytes
      t.string :supported_devices
      t.datetime :released_at
      t.float :user_rating
      t.string :categories

      t.timestamps
    end

    add_index :app_metadatas, :id, :unique => true
    add_index :app_metadatas, [:store_name, :store_id], :unique => true

    # app_metadata_mappings
    create_table :app_metadata_mappings, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :app_id, 'char(36) binary', :null => false
      t.column :app_metadata_id, 'char(36) binary', :null => false
    end

    add_index :app_metadata_mappings, :id, :unique => true
    add_index :app_metadata_mappings, [:app_id, :app_metadata_id], :unique => true
  end

  def self.down
    drop_table :app_metadatas
    drop_table :app_metadata_mappings
  end
end
