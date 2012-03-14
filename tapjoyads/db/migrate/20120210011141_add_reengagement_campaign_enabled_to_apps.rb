class AddReengagementCampaignEnabledToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :reengagement_campaign_enabled, :boolean
  end

  def self.down
    remove_column :apps, :reengagement_campaign_enabled
  end
end
