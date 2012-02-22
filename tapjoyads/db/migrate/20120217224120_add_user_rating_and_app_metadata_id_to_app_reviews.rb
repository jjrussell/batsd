class AddUserRatingAndAppMetadataIdToAppReviews < ActiveRecord::Migration
  def self.up
    add_column :app_reviews, :user_rating, :integer, :default => 0
    add_guid_column :app_reviews, :app_metadata_id, :null => false

    add_index :app_reviews, [ :app_metadata_id, :author_id ], :unique => true
  end

  def self.down
    remove_index :app_reviews, :name => 'index_app_reviews_on_app_metadata_id_and_author_id'
    remove_column :app_reviews, :app_metadata_id
    remove_column :app_reviews, :user_rating
  end
end
