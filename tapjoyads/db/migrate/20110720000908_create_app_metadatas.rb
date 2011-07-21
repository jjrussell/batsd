class CreateAppMetadatas < ActiveRecord::Migration
  def self.up
    # app_metadatas
    create_table :app_metadatas, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :app_id, 'char(36) binary', :null => false
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
    add_index :app_metadatas, [:app_id, :store_name], :unique => true
    add_index :app_metadatas, [:store_name, :store_id], :unique => true

    # app_metadata_mappings
    create_table :app_metadata_mappings, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :app_id, 'char(36) binary', :null => false
      t.column :app_metadata_id, 'char(36) binary', :null => false
    end

    add_index :app_metadata_mappings, :id, :unique => true
    add_index :app_metadata_mappings, [:app_id, :app_metadata_id], :unique => true
    add_index :app_metadata_mappings, [:app_id]
    
    App.find(:all, :conditions => "store_id != ''").each do |app|
      app_metadata = AppMetadata.find(:first, :conditions => ["store_name = ? and store_id = ?", app.store_name, app.store_id])
      if app_metadata == nil
        # only create this record if one doesn't already exist for this store and store_id
        app_metadata = AppMetadata.create!(
          :app_id            => app.id,
          :price             => app.price,
          :store_name        => app.store_name,
          :store_id          => app.store_id,
          :age_rating        => app.age_rating,
          :file_size_bytes   => app.file_size_bytes,
          :supported_devices => app.supported_devices,
          :released_at       => app.released_at,
          :user_rating       => app.user_rating,
          :categories        => app.categories
        )
      end
      
      AppMetadataMapping.create!(
        :app_id     => app.id,
        :app_metadata_id => app_metadata.id
      )
    end
  end

  def self.down
    drop_table :app_metadatas
    drop_table :app_metadata_mappings
  end
end
