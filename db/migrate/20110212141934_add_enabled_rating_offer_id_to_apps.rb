class AddEnabledRatingOfferIdToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :enabled_rating_offer_id, 'char(36) binary'
  end

  def self.down
    remove_column :apps, :enabled_rating_offer_id
  end
end
