class AddDeeplinkOffers < ActiveRecord::Migration

  def self.up
    create_table :deeplink_offers, :id => false  do |t|
      t.guid :id, :null => false
      t.guid :app_id, :null => false
      t.guid :currency_id, :null => false
      t.guid :partner_id, :null => false
      t.string :name, :null => false

      t.timestamps
    end

    add_index "deeplink_offers", ["id"], :name => "index_deeplink_offers_on_id", :unique => true
    add_index "deeplink_offers", ["app_id"], :name => "index_deeplink_offers_on_app_id"
    add_index "deeplink_offers", ["currency_id"], :name => "index_deeplink_offers_on_currency_id"
    add_index "deeplink_offers", ["partner_id"], :name => "index_deeplink_offers_on_partner_id"

    add_guid_column :currencies, :enabled_deeplink_offer_id
  end

  def self.down
    drop_table :deeplink_offers
    remove_column :currencies, :enabled_deeplink_offer_id
  end
end
