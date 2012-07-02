class AddUsesNonHtmlResponsesToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :uses_non_html_responses, :boolean, :null => false, :default => false

    App.cache_all
  end

  def self.down
    remove_column :apps, :uses_non_html_responses
  end
end
