class AddPushNotificationFlagToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :notifications_enabled, :bool, :default => false
  end

  def self.down
    remove_column :apps, :notifications_enabled
  end
end
