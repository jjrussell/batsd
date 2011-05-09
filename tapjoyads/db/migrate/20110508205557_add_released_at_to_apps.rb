class AddReleasedAtToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :released_at, :datetime
    add_column :apps, :user_rating, :float
    add_column :apps, :categories, :string
  end

  def self.down
    remove_column :apps, :released_at
    remove_column :apps, :user_rating
    remove_column :apps, :categories
  end
end
