class AddIsBlankToAppReviews < ActiveRecord::Migration
  def self.up
    add_column :app_reviews, :is_blank, :boolean, :default=>false
    add_index :app_reviews, :is_blank
    AppReview.connection.execute 'UPDATE app_reviews set is_blank=true where text=""'
  end

  def self.down
    remove_column :app_reviews, :is_blank
  end
end
