class AddPublisherNameToAppMetadatas < ActiveRecord::Migration
  def self.up
  	add_column :app_metadatas, :developer, :string
  end

  def self.down
  	remove_column :app_metadatas, :developer
  end
end
