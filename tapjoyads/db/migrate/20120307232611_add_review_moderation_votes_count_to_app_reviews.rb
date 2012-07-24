class AddReviewModerationVotesCountToAppReviews < ActiveRecord::Migration
  def self.up

    add_column :app_reviews, :helpful_votes_count, :integer, :default => 0
    add_column :app_reviews, :bury_votes_count, :integer, :default => 0
    add_column :app_reviews, :helpful_values_sum, :integer, :default => 0
  end

  def self.down
    remove_column :app_reviews, :bury_votes_count
    remove_column :app_reviews, :helpful_votes_count
    remove_column :app_reviews, :helpful_values_sum
  end
end
