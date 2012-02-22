class AddPapayaUserCountToAppMetadatas < ActiveRecord::Migration
  def self.up
    add_column :app_metadatas, :papaya_user_count, :integer
  end

  def self.down
    remove_column :app_metadatas, :papaya_user_count
  end
end
