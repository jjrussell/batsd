class AddRewardedToVideoButtons < ActiveRecord::Migration
  def self.up
    add_column :video_buttons, :rewarded, :boolean, :default => false
  end

  def self.down
    remove_column :video_buttons, :rewarded
  end
end
