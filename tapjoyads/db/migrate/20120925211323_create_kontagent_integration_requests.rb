# 20120925211323
class CreateKontagentIntegrationRequests < ActiveRecord::Migration
  def self.up
    create_table :kontagent_integration_requests do |t|
      t.guid      :id,      :null => false
      t.string    :subdomain
      t.boolean   :successful
      # seems to be on AAA already?
      t.string    :rejection_reason
      #t.string   :partner_id
      #t.string   :user_id
      t.column  :partner_id, 'char(36) binary',  :null => false
      t.column  :user_id, 'char(36) binary',  :null => false
      t.timestamps
    end

    add_column :partners, :kontagent_enabled, :boolean
    add_column :users, :kontagent_enabled, :boolean
    add_column :apps, :kontagent_enabled, :boolean

    add_column :apps, :kontagent_api_key, :string
    add_column :partners, :kontagent_subdomain, :string
  end

  def self.down
    drop_table :kontagent_integration_requests

    remove_column :partners, :kontagent_enabled
    remove_column :users, :kontagent_enabled
    remove_column :apps, :kontagent_enabled

    remove_column :partners, :kontagent_subdomain
    remove_column :apps, :kontagent_api_key
  end
end


