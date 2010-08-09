class Click < SimpledbResource
  
  self.sdb_attr :publisher_app_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :publisher_user_id
  self.sdb_attr :reward_key
  self.sdb_attr :clicked_at,        :type => :time
  self.sdb_attr :installed_at,      :type => :time
  self.sdb_attr :advertiser_amount, :type => :int
  self.sdb_attr :publisher_amount,  :type => :int
  self.sdb_attr :tapjoy_amount,     :type => :int
  self.sdb_attr :currency_reward,   :type => :int
  self.sdb_attr :source
  self.sdb_attr :country
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_CLICK_DOMAINS
    
    return "clicks_#{domain_number}"
  end
  
end
