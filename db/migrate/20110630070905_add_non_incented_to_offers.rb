class AddNonIncentedToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :rewarded, :boolean, :default => true
    rename_column :currencies, :hide_app_installs, :hide_rewarded_app_installs
    rename_column :currencies, :minimum_hide_app_installs_version, :minimum_hide_rewarded_app_installs_version
  end

  def self.down
    remove_column :offers, :rewarded
    rename_column :currencies, :hide_rewarded_app_installs, :hide_app_installs
    rename_column :currencies, :minimum_hide_rewarded_app_installs_version, :minimum_hide_app_installs_version
  end
end
