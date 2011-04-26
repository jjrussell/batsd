class AddHideAppInstallsToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :hide_app_installs, :boolean, :null => false, :default => false
    add_column :currencies, :minimum_hide_app_installs_version, :string, :null => false, :default => ''
  end

  def self.down
    remove_column :currencies, :hide_app_installs
    remove_column :currencies, :minimum_hide_app_installs_version
  end
end
