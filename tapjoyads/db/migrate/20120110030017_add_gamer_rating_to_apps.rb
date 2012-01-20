class AddGamerRatingToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :thumb_up_count, :integer, :default => 0
    add_column :apps, :thumb_down_count, :integer, :default => 0
  end

  def self.down
    remove_column :apps, :thumb_up_count
    remove_column :apps, :thumb_down_count
  end
end
