class AddUserRatingToAppReviews < ActiveRecord::Migration
  def self.up
    add_column :app_reviews, :user_rating, :integer, :default => 0
  end

  def self.down
    remove_column :app_reviews, :user_rating
  end
end
