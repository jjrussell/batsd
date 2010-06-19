class SdbApp < SimpledbResource
  include NewRelicHelper
  
  self.domain_name = 'app'
  self.key_format = 'app_guid'
  
  self.sdb_attr :name,                       {:cgi_escape => true}
  self.sdb_attr :description,                {:cgi_escape => true}
  self.sdb_attr :store_url
  self.sdb_attr :partner_id
  self.sdb_attr :custom_app_id
  self.sdb_attr :payment_for_install,        {:type => :int}
  self.sdb_attr :real_revenue_for_install,   {:type => :int}
  self.sdb_attr :rewarded_installs_ordinal,  {:type => :int}
  self.sdb_attr :install_tracking,           {:type => :bool}
  self.sdb_attr :iphone_only,                {:type => :bool}
  self.sdb_attr :ipad_only,                  {:type => :bool}
  self.sdb_attr :use_raw_url,                {:type => :bool}
  self.sdb_attr :next_run_time,              {:type => :time}
  self.sdb_attr :last_run_time,              {:type => :time}
  self.sdb_attr :last_daily_run_time,        {:type => :time}
  self.sdb_attr :balance,                    {:type => :int}
  self.sdb_attr :price,                      {:type => :int}
  self.sdb_attr :daily_budget,               {:type => :int, :default_value => 0}
  self.sdb_attr :overall_budget,             {:type => :int, :default_value => 0}
  self.sdb_attr :conversion_rate,            {:type => :float}
  self.sdb_attr :show_rate,                  {:type => :float}
  self.sdb_attr :os_type
  self.sdb_attr :primary_color
  self.sdb_attr :countries,                  {:type => :json, :default_value => []}
  self.sdb_attr :postal_codes,               {:type => :json, :default_value => []}
  self.sdb_attr :cities,                     {:type => :json, :default_value => []}
  self.sdb_attr :pay_per_click,              {:type => :bool}
  self.sdb_attr :allow_negative_balance,     {:type => :bool}
  self.sdb_attr :self_promote_only,          {:type => :bool}
  self.sdb_attr :age_rating,                 {:type => :int, :default_value => 0}
  
  ##
  # Returns a url which re-directs the the app store or market for this app.
  # This url is not necessarily a direct url, it may be a linkshare url or a partner's tracking url.
  def get_store_url(udid, publisher_app_id = '')
    if self.use_raw_url
      return self.store_url.
          gsub('TAPJOY_UDID', udid).
          gsub('TAPJOY_PUBLISHER_APP_ID', publisher_app_id)
    end
    
    if get('os_type') == 'android'
      return "market://search?q=#{get('store_url')}"
    else
      store_id = get_store_id
      unless store_id
        return get('store_url')
      end
      
      web_object_url = "http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=#{store_id}&mt=8"
    
      return "http://click.linksynergy.com/fs-bin/click?id=OxXMC6MRBt4&subid=&offerid=146261.1&" +
          "type=10&tmpid=3909&RD_PARM1=#{CGI::escape(web_object_url)}"
    end
    
  end
  
  ##
  # Returns the Apple store id for an app. Determines this from parsing the store url.
  def get_store_id(alert_on_parse_fail = true)
    if self.use_raw_url
      return '00000000'
    end
    
    store_url = get('store_url')
    if store_url.nil?
      if alert_on_parse_fail
        alert_new_relic(ParseStoreIdError, "Could not parse store id from nil store_url for app #{self.to_s}")
      end
      return nil
    end
    
    if self.os_type == 'android'
      return store_url
    end
    
    match = store_url.match(/\/id(\d*)\?/)
    unless match
      match = store_url.match(/[&|?]id=(\d*)/)
    end
    
    unless match and match[1]
      if alert_on_parse_fail
        alert_new_relic(ParseStoreIdError, "Could not parse store id from #{store_url} for app #{self.to_s}")
      end
      return nil
    end
    
    return match[1]
  end
  
  def get_click_url(publisher_app, publisher_user_record, udid)
    return "http://ws.tapjoyads.com/submit_click/store?" +
        "advertiser_app_id=#{@key}" +
        "&publisher_app_id=#{publisher_app.key}" +
        "&publisher_user_record_id=#{publisher_user_record.get_record_id}" +
        "&udid=#{udid}"
  end
  
  def get_redirect_url(publisher_app, publisher_user_record, udid)
    return get_click_url(publisher_app, publisher_user_record, udid) + "&redirect=1"
  end
  
  def get_icon_url(base64 = false)
    if base64
      url = "http://ws.tapjoyads.com/get_app_image/icon?app_id=#{@key}"
    else
      url = "https://s3.amazonaws.com/app_data/icons/#{@key}.png"
    end
    return url
  end
  
  def is_free
    return get('price').to_i <= 0
  end
  
  ##
  # Return the string 'Free' or 'Paid'.
  def get_cost
    return is_free ? 'Free' : 'Paid'
  end
  
  def to_s
    "#{self.name} (#{@key})"
  end
end