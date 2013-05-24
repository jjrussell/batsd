class RemoveDeprecatedAppColumns < ActiveRecord::Migration
  def self.up
    remove_column :apps, :description
    remove_column :apps, :price
    remove_column :apps, :store_id
    remove_column :apps, :age_rating
    remove_column :apps, :file_size_bytes
    remove_column :apps, :supported_devices
    remove_column :apps, :released_at
    remove_column :apps, :user_rating
    remove_column :apps, :categories
    remove_column :apps, :countries_blacklist
    remove_column :apps, :papaya_user_count
  end

  def self.down
    add_column :apps, :description, :text
    add_column :apps, :price, :integer, :default => 0
    add_column :apps, :store_id, :string, :null => false
    add_column :apps, :age_rating, :integer
    add_column :apps, :file_size_bytes, :integer
    add_column :apps, :supported_devices, :string
    add_column :apps, :released_at, :datetime
    add_column :apps, :user_rating, :float
    add_column :apps, :categories, :string
    add_column :apps, :countries_blacklist, :text
    add_column :apps, :papaya_user_count, :integer
  end
end
