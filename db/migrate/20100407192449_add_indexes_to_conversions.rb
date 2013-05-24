class AddIndexesToConversions < ActiveRecord::Migration
  def self.up
    add_index :conversions, :reward_id
    add_index :conversions, :advertiser_app_id
    add_index :conversions, :publisher_app_id
    add_index :conversions, :created_at
  end

  def self.down
    # no down
  end
end
