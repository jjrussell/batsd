##
# Represents a single click to the app store.
class StoreClick < SimpledbResource
  self.domain_name = 'store-click'
  self.key_format = 'udid.advertiser_offer_id'
  
  self.sdb_attr :publisher_app_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :publisher_user_id
  self.sdb_attr :reward_key
  self.sdb_attr :click_date,        :type => :time
  self.sdb_attr :clicked_at,        :type => :time, :attr_name => :click_date
  self.sdb_attr :installed,         :type => :time
  self.sdb_attr :installed_at,      :type => :time, :attr_name => :installed
  self.sdb_attr :advertiser_amount, :type => :int
  self.sdb_attr :publisher_amount,  :type => :int
  self.sdb_attr :tapjoy_amount,     :type => :int
  self.sdb_attr :offerpal_amount,   :type => :int
  self.sdb_attr :currency_reward,   :type => :int
  self.sdb_attr :source
  self.sdb_attr :country
  
  ##
  # Gets the udid from the key
  def udid
    return @key.split('.')[0]
  end
end