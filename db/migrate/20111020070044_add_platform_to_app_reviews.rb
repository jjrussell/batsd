class AddPlatformToAppReviews < ActiveRecord::Migration
  def self.up
    add_column :app_reviews, :platform, :string
    remove_index :app_reviews, :featured_on
    add_index :app_reviews, [:featured_on, :platform], :unique => true
  end

  def self.down
    remove_column :app_reviews, :platform
    add_index :app_reviews, :featured_on, :unique => true
    remove_index :app_reviews, [:featured_on, :platform]
  end
end
