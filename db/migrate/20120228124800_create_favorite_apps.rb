class CreateFavoriteApps < ActiveRecord::Migration
  def self.up
    create_table :favorite_apps, :id => false do |t|

      t.guid :id, :null => false
      t.guid :gamer_id, :null => false
      t.guid :app_metadata_id, :null => false

      t.timestamps
    end
    add_index :favorite_apps, :id, :unique => true
    add_index :favorite_apps, [:gamer_id, :app_metadata_id], :unique => true
    add_index :favorite_apps, :app_metadata_id
  end

  def self.down
    drop_table :favorite_apps
  end
end
