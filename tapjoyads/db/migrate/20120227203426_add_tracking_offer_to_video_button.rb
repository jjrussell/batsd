class AddTrackingOfferToVideoButton < ActiveRecord::Migration
  def self.up
    add_guid_column :video_buttons, :tracking_offer_id
  end

  def self.down
    remove_column :video_buttons, :tracking_offer_id
  end
end
