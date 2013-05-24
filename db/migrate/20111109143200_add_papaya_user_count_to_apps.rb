class AddPapayaUserCountToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :papaya_user_count, :integer
  end

  def self.down
    remove_column :apps, :papaya_user_count
  end
end
