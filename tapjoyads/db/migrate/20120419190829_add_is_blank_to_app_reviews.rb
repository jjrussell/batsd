class AddIsBlankToAppReviews < ActiveRecord::Migration
  def self.up
    add_column :app_reviews, :is_blank, :boolean, :default=>false
    add_index :app_reviews,
              [:app_metadata_id, :updated_at,:is_blank ],
              { :name => "app_reviews_get_app",
               :order => {:updated_at => :desc} }
    AppReview.connection.execute 'UPDATE app_reviews set is_blank=true where text=""'
  end

  def self.down
    remove_index :app_reviews, :app_reviews_get_app
    remove_index :app_reviews, :is_blank
    remove_column :app_reviews, :is_blank
  end
end
