class AddGamerRatingToAppMetadatas < ActiveRecord::Migration
  def self.up
    add_column :app_metadatas, :thumbs_up, :integer, :default => 0
    add_column :app_metadatas, :thumbs_down, :integer, :default => 0
  end

  def self.down
    remove_column :app_metadatas, :thumbs_up
    remove_column :app_metadatas, :thumbs_down
  end
end
