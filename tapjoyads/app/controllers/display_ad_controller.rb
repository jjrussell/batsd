class DisplayAdController < ApplicationController
  
  # A hard-coded list of publisher apps that support ABC ads. The main requirement is that
  # udid == publisher_user_id.
  @@allowed_publisher_apps = Set.new([
      "41df65f0-593c-470b-83a4-37be66740f34", # TapResort
      "2349536b-c810-47d7-836c-2cd47cd3a796", # TapDefense
      ])
  
  before_filter :setup, :except => :image
  
  def index
  end
  
  def webview
    render :layout => false
  end
  
  def image
    return unless verify_params([ :publisher_app_id, :advertiser_app_id, :displayer_app_id, :size ], { :allow_empty => false })
    
    web_request = WebRequest.new
    web_request.put_values('display_ad_image', params, get_ip_address, get_geoip_data)
    web_request.save
    
    publisher = App.find_in_cache(params[:publisher_app_id])
    offer = Offer.find_in_cache(params[:advertiser_app_id])
    
    ad_image_base64 = get_ad_image(publisher, offer)
    
    send_data Base64.decode64(ad_image_base64), :type => 'image/png', :disposition => 'inline'
  end
  
private

  def setup
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

    # Randomly choose a free offer that is converting at greater than 50%
    offer_list, more_data_available = publisher_app.get_offer_list(params[:udid], 
       :device_type => params[:device_type],
       :geoip_data => geoip_data,
       :required_length => 25,
       :reject_rating_offer => true)
    
    offer_list.reject! do |offer|
      offer.is_paid? || offer.conversion_rate < 0.5
    end
    srand
    offer = offer_list[rand(offer_list.size)]
    
    @click_url = offer.get_redirect_url(publisher_app, params[:udid], params[:udid], 'display_ad', nil, params[:app_id])
    @image = get_ad_image(publisher_app, offer)
  end

  def get_ad_image(publisher, offer)
    
    Mc.get_and_put("display_ad.#{publisher.id}.#{offer.id}", false, 1.hour) do
      width = 320
      height = 48
      border = 2
      
      publisher_icon_blob = Downloader.get("http://s3.amazonaws.com/app_data/icons/#{publisher.id}.png")
      offer_icon_blob = Downloader.get("http://s3.amazonaws.com/app_data/icons/#{offer.id}.png")

      icon_height = height - border * 2 - 2
      publisher_icon = Magick::Image.from_blob(publisher_icon_blob)[0].resize(icon_height, icon_height)
      offer_icon = Magick::Image.from_blob(offer_icon_blob)[0].resize(icon_height, icon_height)

      img = Magick::Image.new(width - border * 2, height - border * 2)
      img.format = 'png'

      img.composite!(publisher_icon, 1, 1, Magick::AtopCompositeOp)
      img.composite!(offer_icon, width - icon_height - 5, 1, Magick::AtopCompositeOp)

      text = "Earn #{publisher.currency.get_reward_amount(offer)} #{publisher.currency.name} in #{publisher.name}!\n Install #{offer.name} for free."
      image_label = Magick::Image.read("label:#{text}") do
        self.size = "220x44"
        self.gravity = Magick::CenterGravity
        self.stroke = 'transparent'
      end
      img.composite!(image_label[0], 50, 0, Magick::AtopCompositeOp)

      img.border!(border, border, 'black')
      
      Base64.encode64(img.to_blob)
    end
  end
  
end