class RemoveCustomUrlSchemeFromApps < ActiveRecord::Migration
  def self.up
    remove_column :apps, :custom_url_scheme
  end

  def self.down
    add_column :apps, :custom_url_scheme, :string
  end
end
