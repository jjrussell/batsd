class AddScreenshotsToAppMetadatas < ActiveRecord::Migration
  def self.up
    add_column :app_metadatas, :screenshots, :text
  end

  def self.down
    remove_column :app_metadatas, :screenshots
  end
end
