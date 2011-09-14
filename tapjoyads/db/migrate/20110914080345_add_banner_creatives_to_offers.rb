class AddBannerCreativesToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :banner_creatives, :text
  end

  def self.down
    remove_column :offers, :banner_creatives
  end
end
