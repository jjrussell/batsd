class AddHiddenFields < ActiveRecord::Migration
  def self.up
    add_column :apps, :hidden, :boolean, :default => false, :null => false
    add_column :email_offers, :hidden, :boolean, :default => false, :null => false
    add_column :rating_offers, :hidden, :boolean, :default => false, :null => false
    add_column :offerpal_offers, :hidden, :boolean, :default => false, :null => false
    add_column :offers, :hidden, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :offers, :hidden
    remove_column :offerpal_offers, :hidden
    remove_column :rating_offers, :hidden
    remove_column :email_offers, :hidden
    remove_column :apps, :hidden
  end
end
