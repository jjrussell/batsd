class UpdateAppReviews < ActiveRecord::Migration
  def self.up
    remove_index :app_reviews, [:featured_on, :platform]
    remove_column :app_reviews, :featured_on
    
    
    add_column :app_reviews, :user_rating, :integer, :default => 0
  end

  def self.down
    remove_column :app_reviews, :user_rating

    add_column :app_reviews, :featured_on, :date
    add_index :app_reviews, [:featured_on, :platform], :unique => true
  end
end
