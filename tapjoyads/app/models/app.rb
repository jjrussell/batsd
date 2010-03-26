class App < SimpledbResource
  include NewRelicHelper
  
  self.domain_name = 'app'
  self.key_format = 'app_guid'
  
  self.sdb_attr :name,                       {:cgi_escape => true}
  self.sdb_attr :description,                {:cgi_escape => true}
  self.sdb_attr :store_url
  self.sdb_attr :partner_id
  self.sdb_attr :payment_for_install,        {:type => :int}
  self.sdb_attr :real_revenue_for_install,   {:type => :int}
  self.sdb_attr :rewarded_installs_ordinal,  {:type => :int}
  self.sdb_attr :install_tracking,           {:type => :bool}
  self.sdb_attr :iphone_only,                {:type => :bool}
  self.sdb_attr :use_raw_url,                {:type => :bool}
  self.sdb_attr :next_run_time,              {:type => :time}
  self.sdb_attr :last_run_time,              {:type => :time}
  self.sdb_attr :balance,                    {:type => :int}
  self.sdb_attr :price,                      {:type => :int}
  self.sdb_attr :daily_budget,               {:type => :int, :default_value => 0}
  self.sdb_attr :conversion_rate,            {:type => :float}
  self.sdb_attr :show_rate,                  {:type => :float}
  self.sdb_attr :os_type
  self.sdb_attr :primary_color
  self.sdb_attr :countries,                  {:type => :json, :default_value => []}
  self.sdb_attr :postal_codes,               {:type => :json, :default_value => []}
  
  ##
  # Returns a list of Apps which are advertising in this app.
  # Apps which are specifically banned by this app are filtered out.
  # Also, apps that the device has already installed are also filtered.
  # udid: The udid of the device for which to filter apps that are already installed.
  # options:
  #   currency: This app's currency. If none is provided, one is created using this app's key.
  #   iphone: Whether the device making this request is an iphone. Used to reject iphone-only apps.
  def get_advertiser_app_list(udid, options = {})
    currency = options.delete(:currency)
    iphone = options.delete(:iphone) { true }
    country = options.delete(:country)
    postal_code = options.delete(:postal_code)
    start = options.delete(:start) { 0 }
    max = options.delete(:max) { 25 }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    device_app_list = DeviceAppList.new(:key => udid)
    currency = Currency.new(:key => @key) unless currency
    
    json_string = get_from_cache_and_save("s3.offer-data.rewarded_installs_list") do
      bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
      bucket.get('rewarded_installs_list')
    end
    
    serialized_advertiser_app_list = JSON.parse(json_string)

    advertiser_app_list = []
    serialized_advertiser_app_list.each do |serialized_advertiser_app|
      advertiser_app_list.push(App.deserialize(serialized_advertiser_app))
    end
    
    banned_apps = (currency.get('disabled_apps') || '').split(';')
    
    only_free_apps = currency.get('only_free_apps') == '1'
    
    count = 0
    advertiser_app_list.reject! do |advertiser_app|
      count += 1
      
      reject = false
      
      reject = true if banned_apps.include?(advertiser_app.key)
      reject = true if only_free_apps and not advertiser_app.is_free
      reject = true if advertiser_app.key == @key
      reject = true if advertiser_app.iphone_only and not iphone
      reject = true if advertiser_app.os_type == 'iphone' and self.os_type == 'android'
      reject = true if advertiser_app.os_type == 'android' and self.os_type == 'iphone'
      
      reject = true unless advertiser_app.countries.empty? or advertiser_app.countries.include?(country)
      reject = true unless advertiser_app.postal_codes.empty? or advertiser_app.postal_codes.include?(postal_code)
      
      unless udid == '298c5159a3681207eaba5a04b3573aa7b4f13d99' # Ben's udid. Show all apps on his device.
        reject = true if device_app_list.has_app(advertiser_app.key)
        srand((udid + (Time.now.to_f / 1.hour).to_i.to_s + advertiser_app.key).hash)
        reject = true if rand > (advertiser_app.get('show_rate') || 1).to_f
      end
      
      reject
    end
    
    return advertiser_app_list
  end
  
  ##
  # Returns a list of active offers that are not disabled for this app.
  # currency: This app's currency. If none is provided, one is created using this app's key.
  def get_offer_list(currency = nil)
    currency = Currency.new(:key => @key) unless currency
    
    json_string = get_from_cache_and_save("s3.offer-data.offer_list") do
      bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
      bucket.get('offer_list')
    end
    serialized_offer_list = JSON.parse(json_string)
    offer_list = []
    serialized_offer_list.each do |serialized_offer|
      offer_list.push(CachedOffer.deserialize(serialized_offer))
    end
    
    banned_offers = (currency.get('disabled_offers') || '').split(';')
    
    offer_list.reject! do |offer|
      banned_offers.include?(offer.key)
    end
    
    return offer_list
  end
  
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
      
      web_object_url = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=#{store_id}&mt=8"
    
      return "http://click.linksynergy.com/fs-bin/click?id=OxXMC6MRBt4&subid=&offerid=146261.1&" +
          "type=10&tmpid=3909&RD_PARM1=#{CGI::escape(web_object_url)}"
    end
    
  end
  
  ##
  # Returns the Apple store id for an app. Determines this from parsing the store url.
  def get_store_id
    if self.use_raw_url
      return '00000000'
    end
    
    store_url = get('store_url')
    if self.os_type == 'android'
      return store_url
    end
    
    match = store_url.match(/\/id(\d*)\?/)
    unless match
      match = store_url.match(/[&|?]id=(\d*)/)
    end
    
    unless match and match[1]
      alert_new_relic(ParseStoreIdError, "Could not parse store id from #{store_url} for app #{self.to_s}")
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