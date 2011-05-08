class AddReleasedAtToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :released_at, :datetime
  end

  def self.down
    remove_column :apps, :released_at
  end
end
