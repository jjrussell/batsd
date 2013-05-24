class AddUrlOverriddenToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :url_overridden, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :url_overridden
  end
end
