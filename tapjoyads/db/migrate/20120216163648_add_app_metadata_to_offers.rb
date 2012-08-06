class AddAppMetadataToOffers < ActiveRecord::Migration
  def self.up
    add_guid_column :offers, :app_metadata_id
    add_index :offers, [ :app_metadata_id ]
  end

  def self.down
    remove_index :offers, [ :app_metadata_id ]
    remove_column :offers, :app_metadata_id
  end
end
