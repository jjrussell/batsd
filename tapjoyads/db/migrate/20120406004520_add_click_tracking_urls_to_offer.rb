class AddClickTrackingUrlsToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :click_tracking_urls, :text
  end

  def self.down
    remove_column :offers, :click_tracking_urls
  end
end
