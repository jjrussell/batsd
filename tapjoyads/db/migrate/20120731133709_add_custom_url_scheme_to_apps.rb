class AddCustomUrlSchemeToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :custom_url_scheme, :string
  end

  def self.down
    remove_column :apps, :custom_url_scheme
  end
end

