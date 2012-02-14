class AddFeaturedContentColumnsToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :tracking_for_type, :string
    add_guid_column :offers, :tracking_for_id
    add_index :offers, [ :tracking_for_type, :tracking_for_id ], :unique => true
  end

  def self.down
    remove_index :offers, :name => 'index_offers_on_tracking_for_type_and_tracking_for_id'
    remove_column :offers, :tracking_for_id
    remove_column :offers, :tracking_for_type
  end
end
