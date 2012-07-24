class AddConversionTrackingUrlsToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :conversion_tracking_urls, :text
  end

  def self.down
    remove_column :offers, :conversion_tracking_urls
  end
end
