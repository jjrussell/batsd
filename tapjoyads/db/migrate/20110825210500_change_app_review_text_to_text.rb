class ChangeAppReviewTextToText < ActiveRecord::Migration
  def self.up
    change_column :app_reviews, :text, :text
    add_index :app_reviews, :featured_on, :unique => true
  end

  def self.down
    change_column :app_reviews, :text, :string
    remove_index :app_reviews, :featured_on
  end
end
