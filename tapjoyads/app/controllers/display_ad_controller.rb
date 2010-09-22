class DisplayAdController < ApplicationController
  
  ##
  # A hard-coded list of publisher apps that support ABC ads. The main requirement is that
  # udid == publisher_user_id.
  @@allowed_publisher_apps = Set.new([
      "41df65f0-593c-470b-83a4-37be66740f34", # TapResort
      "2349536b-c810-47d7-836c-2cd47cd3a796", # TapDefense
      ])
  
  def index
    return unless verify_params([ :app_id, :udid ], { :allow_empty => false })

    now = Time.zone.now

    geoip_data = get_geoip_data
    
    web_request = WebRequest.new
    web_request.put_values('display_ad', params, get_ip_address, geoip_data)
    web_request.save

    # Randomly choose one publisher app that the user has run:
    device_app_list = DeviceAppList.new(:key => params[:udid])
    publisher_apps = []
    @@allowed_publisher_apps.each do |app_id|
     last_run_time = device_app_list.last_run_time(app_id)
     if last_run_time.present? && last_run_time > now - 1.week
       publisher_apps << app_id
     end
    end
    return if publisher_apps.empty?
    publisher_app_id = publisher_apps[rand(publisher_apps.size)]
    publisher_app = App.find_in_cache(publisher_app_id)

    # Randomly choose an offer
    offer_list, more_data_available = publisher_app.get_offer_list(params[:udid], 
       :device_type => params[:device_type],
       :geoip_data => geoip_data,
       :required_length => 25,
       :reject_rating_offer => true,
       :show_secondary_offers => true)
    srand
    offer = offer_list[rand(offer_list.size)]
    
    @click_url = offer.get_redirect_url(publisher_app, params[:udid], params[:udid], 'display_ad', nil, params[:app_id])
    @image_url = "http://ws.tapjoyads.com/display_ad/image" +
       "?publisher_app_id=#{publisher_app.id}" + 
       "&advertiser_app_id=#{offer.id}" +
       "&display_app_id=#{params[:app_id]}" +
       "&size=320x48"
  end
  
  def image
    return unless verify_params([ :publisher_app_id, :advertiser_app_id, :display_app_id, :size ], { :allow_empty => false })
    
    web_request = WebRequest.new
    web_request.put_values('display_ad_image', params, get_ip_address, get_geoip_data)
    web_request.save
    
    # TODO: actually generate an image
    
  end
  
end