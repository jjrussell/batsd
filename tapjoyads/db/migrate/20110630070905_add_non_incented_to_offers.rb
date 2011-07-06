class AddNonIncentedToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :incentivized, :boolean, :default => true
    rename_column :currencies, :hide_app_installs, :hide_incentivized_app_installs
    rename_column :currencies, :minimum_hide_app_installs_version, :minimum_hide_incentivized_app_installs_version
  end

  def self.down
    remove_column :offers, :incentivized
    rename_column :currencies, :hide_incentivized_app_installs, :hide_app_installs
    rename_column :currencies, :minimum_hide_incentivized_app_installs_version, :minimum_hide_app_installs_version
  end
end
