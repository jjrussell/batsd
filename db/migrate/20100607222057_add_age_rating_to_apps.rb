class AddAgeRatingToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :age_rating, :integer
  end

  def self.down
    remove_column :apps, :age_rating
  end
end
