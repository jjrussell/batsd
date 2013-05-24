class AddCookieTrackingToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :cookie_tracking, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :cookie_tracking
  end
end
