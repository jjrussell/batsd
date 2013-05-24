class ChangeAdvertiserAppIdToAdvertiserOfferId < ActiveRecord::Migration
  def self.up
    rename_column :conversions, :advertiser_app_id, :advertiser_offer_id
  end

  def self.down
    rename_column :conversions, :advertiser_offer_id, :advertiser_app_id
  end
end
