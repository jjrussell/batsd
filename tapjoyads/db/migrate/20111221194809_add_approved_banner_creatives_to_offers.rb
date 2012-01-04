class AddApprovedBannerCreativesToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :approved_banner_creatives, :text
  end

  def self.down
    remove_column :offers, :approved_banner_creatives
  end
end
