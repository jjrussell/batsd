class CreateEnableOfferRequests < ActiveRecord::Migration
  def self.up
    create_table :enable_offer_requests, :id => false do |t|
      t.column  :id, 'char(36) binary', :null => false
      t.column  :offer_id, 'char(36) binary', :null => false
      t.column  :requested_by_id, 'char(36) binary', :null => false
      t.column  :assigned_to_id, 'char(36) binary'
      t.integer :status, :default => 0

      t.timestamps
    end
    add_index :enable_offer_requests, :id, :unique => true
    add_index :enable_offer_requests, :status
    add_index :enable_offer_requests, :offer_id
  end

  def self.down
    drop_table :enable_offer_requests
  end
end
