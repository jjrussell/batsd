class AddPapayaTotalUserToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :papaya_total_user, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :apps, :papaya_total_user
  end
end
