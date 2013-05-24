class VideoOfferTargeting < ActiveRecord::Migration
  def self.up
    add_column :video_offers, :app_targeting, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :video_offers, :app_targeting
  end
end
