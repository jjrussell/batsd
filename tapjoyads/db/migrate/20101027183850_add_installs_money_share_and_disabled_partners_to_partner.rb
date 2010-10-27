class AddInstallsMoneyShareAndDisabledPartnersToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :disabled_partners, :text, :null => false, :default => ''
    add_column :partners, :installs_money_share, :decimal, :precision => 8, :scale => 6, :null => false, :default => 0.5
  end

  def self.down
    remove_column :partners, :disabled_partners
    remove_column :partners, :installs_money_share
  end
end
