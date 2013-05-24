class ChangeAppReviewAppIdNilable < ActiveRecord::Migration
  def self.up
    change_column_null :app_reviews, :app_id, true
  end

  def self.down
    change_column_null :app_reviews, :app_id, false
  end
end
