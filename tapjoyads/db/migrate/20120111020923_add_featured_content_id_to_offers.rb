class AddFeaturedContentIdToOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :offers, :featured_content_id, :null => true, :default => nil
    add_index :offers, :featured_content_id, :unique => true
  end

  def self.down
    remove_index :offers, :featured_content_id
    remove_column :offers, :featured_content_id
  end
end