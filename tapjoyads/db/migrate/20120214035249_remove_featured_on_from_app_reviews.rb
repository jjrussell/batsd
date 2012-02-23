class RemoveFeaturedOnFromAppReviews < ActiveRecord::Migration
  def self.up
    remove_index :app_reviews, [:featured_on, :platform]
    remove_column :app_reviews, :featured_on
  end

  def self.down
    add_column :app_reviews, :featured_on, :date
    add_index :app_reviews, [:featured_on, :platform], :unique => true
  end
end
