class RecreateAndReindexConversions < ActiveRecord::Migration
  def self.up
    drop_table :conversions

    create_table :conversions, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :reward_id, 'char(36) binary'
      t.column :advertiser_offer_id, 'char(36) binary'
      t.column :publisher_app_id, 'char(36) binary', :null => false
      t.integer :advertiser_amount, :null => false
      t.integer :publisher_amount, :null => false
      t.integer :tapjoy_amount, :null => false
      t.integer :reward_type, :null => false
      t.timestamps
    end

    add_index :conversions, [ :id, :created_at ], :unique => true
    add_index :conversions, :created_at
    add_index :conversions, [ :advertiser_offer_id, :created_at, :reward_type ], :name => 'index_on_advertiser_offer_id_created_at_and_reward_type'
    add_index :conversions, [ :publisher_app_id, :created_at, :reward_type ], :name => 'index_on_publisher_app_id_created_at_and_reward_type'

    if Rails.env.production?
      partition_sql  = "ALTER TABLE conversions PARTITION BY RANGE (TO_DAYS(created_at)) ("
      partition_sql +=   "PARTITION p734534 VALUES LESS THAN (734534) COMMENT 'created_at < 2011-02-01 00:00:00',"
      partition_sql +=   "PARTITION p734562 VALUES LESS THAN (734562) COMMENT 'created_at < 2011-03-01 00:00:00'"
      partition_sql += ")"
      Conversion.connection.execute(partition_sql)
    end
  end

  def self.down
    # no down
  end
end
