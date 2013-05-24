class AddPrimaryColumnToAppMetadataMappings < ActiveRecord::Migration
  def self.up
    add_column :app_metadata_mappings, :is_primary, :boolean, :default => false
  end

  def self.down
    remove_column :app_metadata_mappings, :is_primary
  end
end
