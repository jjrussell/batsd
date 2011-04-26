class AddHideAppInstallsToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :hide_app_installs, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :currencies, :hide_app_installs
  end
end
