class AddFeaturedAdFieldsToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :featured_ad_content, :text
    add_column :offers, :featured_ad_action, :string
    add_column :offers, :featured_ad_color, :string
  end

  def self.down
    remove_column :offers, :featured_ad_content
    remove_column :offers, :featured_ad_action
    remove_column :offers, :featured_ad_color
  end
end
