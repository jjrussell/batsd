class AddReceiveCampaignEmailsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :receive_campaign_emails, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :users, :receive_campaign_emails
  end
end
