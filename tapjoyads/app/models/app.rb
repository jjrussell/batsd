class App < SimpledbResource
  self.domain_name = 'app'
  self.key_format = 'app_guid'
  
  ##
  # Returns a list of Apps which are advertising in this app.
  # Apps which are specifically banned by this app are filtered out.
  # Also, apps that the device has already installed are also filtered.
  # udid: The udid of the device for which to filter apps that are already installed.
  # options:
  #   currency: This app's currency. If none id provided, one is created using this app's key.
  #   iphone: Whether the device making this request is an iphone. Used to reject iphone-only apps.
  def get_advertiser_app_list(udid, options = {})
    currency = options.delete(:currency)
    iphone = options.delete(:iphone) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    device_app_list = DeviceAppList.new(:key => udid)
    currency = Currency.new(:key => @key) unless currency
    
    json_string = get_from_cache_and_save("installs.rewarded_installs_list") do
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
    srand((udid + (Time.now.to_f / 1.hour).to_i.to_s).hash)
    
    advertiser_app_list.reject! do |advertiser_app|
      reject = false
      
      reject = true if banned_apps.include?(advertiser_app.key)
      reject = true if only_free_apps and not advertiser_app.is_free
      reject = true if advertiser_app.key == @key
      reject = true if advertiser_app.get('iphone_only') == '1' and not iphone
      
      if udid != '298c5159a3681207eaba5a04b3573aa7b4f13d99' # Ben's udid. Show all apps on his device.
        reject = true if device_app_list.has_app(advertiser_app.key)
        reject = true if rand > (advertiser_app.get('show_rate') || 1).to_f
      end
      
      reject
    end
    
    return advertiser_app_list
  end
  
  def get_linkshare_url(request = nil, params = nil)
    store_url = get('store_url')
    
    match = store_url.match(/\/id(\d*)\?/)
    unless match
      match = store_url.match(/[&|?]id=(\d*)/)
    end
    
    unless match and match[1]
      if request and params
        NewRelic::Agent.agent.error_collector.notice_error(
            Exception.new("Could not parse store id from #{store_url}"),
            request, action, params)
      end
      return store_url
    end
    
    store_id = match[1]
    web_object_url = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=#{store_id}&mt=8"
    
    return "http://click.linksynergy.com/fs-bin/click?id=OxXMC6MRBt4&subid=&offerid=146261.1&" +
        "type=10&tmpid=3909&RD_PARM1=#{CGI::escape(web_object_url)}"
  end
  
  def get_click_url(publisher_app, publisher_user_record, udid)
    "http://ws.tapjoyads.com/submit_click/store?" +
        "advertiser_app_id=#{@key}" +
        "&publisher_app_id=#{publisher_app.key}" +
        "&publisher_user_record_id=#{publisher_user_record.get_record_id}" +
        "&udid=#{udid}"
  end
  
  def get_redirect_url(publisher_app, publisher_user_record, udid)
    return get_click_url(publisher_app, publisher_user_record, udid) + "&redirect=1"
  end
  
  def get_icon_url(base64 = false)
    url = "http://ws.tapjoyads.com/get_app_image/icon?app_id=#{@key}"
    url += "&img=1" unless base64
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
end