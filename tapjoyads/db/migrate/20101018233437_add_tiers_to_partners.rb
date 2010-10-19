class AddTiersToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :calculated_advertiser_tier, :integer
    add_column :partners, :calculated_publisher_tier, :integer
    add_column :partners, :custom_advertiser_tier, :integer
    add_column :partners, :custom_publisher_tier, :integer
  end

  def self.down
    remove_column :partners, :custom_publisher_tier
    remove_column :partners, :custom_advertiser_tier
    remove_column :partners, :calculated_publisher_tier
    remove_column :partners, :calculated_advertiser_tier
  end
end
