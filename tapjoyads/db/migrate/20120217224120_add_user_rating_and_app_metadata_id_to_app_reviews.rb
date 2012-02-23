class AddUserRatingAndAppMetadataIdToAppReviews < ActiveRecord::Migration
  def self.up
    add_column :app_reviews, :user_rating, :integer, :default => 0
    add_guid_column :app_reviews, :app_metadata_id, :null => false
  end

  def self.down
    remove_column :app_reviews, :app_metadata_id
    remove_column :app_reviews, :user_rating
  end
end
