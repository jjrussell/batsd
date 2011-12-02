class AddColumnsToConversions < ActiveRecord::Migration
  def self.up
    add_guid_column :conversions, :publisher_partner_id, :null => false
    add_guid_column :conversions, :advertiser_partner_id, :null => false
    add_column :conversions, :publisher_reseller_id, :string, :limit => 36
    add_column :conversions, :advertiser_reseller_id, :string, :limit => 36
    add_column :conversions, :spend_share, :float

    add_index :conversions, [ :publisher_partner_id, :created_at ]
    add_index :conversions, [ :advertiser_partner_id, :created_at ]
  end

  def self.down
    remove_index :conversions, [ :publisher_partner_id, :created_at ]
    remove_index :conversions, [ :advertiser_partner_id, :created_at ]

    remove_column :conversions, :publisher_partner_id
    remove_column :conversions, :advertiser_partner_id
    remove_column :conversions, :publisher_reseller_id
    remove_column :conversions, :advertiser_reseller_id
    remove_column :conversions, :spend_share
  end
end
