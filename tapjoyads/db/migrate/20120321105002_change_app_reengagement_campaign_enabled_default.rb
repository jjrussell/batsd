class ChangeAppReengagementCampaignEnabledDefault < ActiveRecord::Migration
  def self.up
    remove_column :apps, :reengagement_campaign_enabled
    add_column :apps, :reengagement_campaign_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :apps, :reengagement_campaign_enabled
    add_column :apps, :reengagement_campaign_enabled, :boolean
  end
end
