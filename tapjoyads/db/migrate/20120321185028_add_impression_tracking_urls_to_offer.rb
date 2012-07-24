class AddImpressionTrackingUrlsToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :impression_tracking_urls, :text
  end

  def self.down
    remove_column :offers, :impression_tracking_urls
  end
end
