class AddIndexOnAppMetadataIdAndAuthorIdToAppReviews < ActiveRecord::Migration
  def self.up
    add_index :app_reviews, [ :app_metadata_id, :author_id ], :unique => true
  end

  def self.down
    remove_index :app_reviews, :name => 'index_app_reviews_on_app_metadata_id_and_author_id'
  end
end
