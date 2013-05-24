class AddLanguagesToAppMetadatas < ActiveRecord::Migration
  def self.up
    add_column :app_metadatas, :languages, :text
  end

  def self.down
    remove_column :app_metadatas, :languages
  end
end
