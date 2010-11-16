class DisplayAdController < ApplicationController
  
  # A hard-coded list of publisher apps that support ABC ads.
  @@allowed_publisher_app_ids = Set.new([
      "41df65f0-593c-470b-83a4-37be66740f34", # Tap Resort
      "262294a6-0304-48d9-a6d0-e0b7bf60f345", # Tap Resport Party
      "9dfa6164-9449-463f-acc4-7a7c6d7b5c81", # TapFish
      "b91369a6-36bc-4ede-80e5-009f48466539", # Tap Birds
      "0fd33f9d-5edf-4377-941c-3b93e5814f39", # Tap Ranch
      "c3fc6075-57a9-41d1-b0ee-e1c0cbbe4ef3", # Tap Zoo
      ])
  
  before_filter :setup, :except => :image
  
  def index
  end
  
  def webview
    if @click_url.present? && @image.present?
      render :layout => false
    else
      render :text => ''
    end
  end
  
  def image
    return unless verify_params([ :publisher_app_id, :advertiser_app_id, :displayer_app_id, :size ])
    
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
    return unless verify_params([ :app_id, :udid ])

    now = Time.zone.now
    geoip_data = get_geoip_data
    params[:displayer_app_id] = params[:app_id]
    
    web_request = WebRequest.new(:time => now)
    web_request.put_values('display_ad_requested', params, get_ip_address, geoip_data)
    
    # Randomly choose one publisher app that the user has run:
    device = Device.new(:key => params[:udid])
    publisher_app_ids = []
    @@allowed_publisher_app_ids.each do |app_id|
     last_run_time = device.last_run_time(app_id)
     if last_run_time.present? && last_run_time > now - 1.week
       publisher_app_ids << app_id
     end
    end
    
    unless publisher_app_ids.empty?
      publisher_app_id = publisher_app_ids[rand(publisher_app_ids.size)]
      publisher_app = App.find_in_cache(publisher_app_id)
      currency = Currency.find_in_cache(publisher_app_id)

      # Randomly choose a free offer that is converting at greater than 50%
      offer_list, more_data_available = publisher_app.get_offer_list(params[:udid], 
         :currency => currency,
         :device_type => params[:device_type],
         :geoip_data => geoip_data,
         :required_length => 25,
         :reject_rating_offer => true)
    
      offer_list.reject! do |offer|
        offer.is_paid? || offer.conversion_rate < 0.5 || offer.item_id == params[:app_id] || offer.name.size > 30
      end
      srand
      offer = offer_list[rand(offer_list.size)]
    
      if offer.present?
        @click_url = offer.get_click_url(publisher_app, get_user_id_from_udid(params[:udid], params[:app_id]), params[:udid], currency.id, 'display_ad', nil, now, params[:app_id])
        @image = get_ad_image(publisher_app, offer)
      
        params[:offer_id] = offer.id
        params[:publisher_app_id] = publisher_app.id
        
        web_request.add_path('display_ad_shown')
      end
    end
      
    web_request.save
  end

  def get_ad_image(publisher, offer)
    
    Mc.get_and_put("display_ad.#{publisher.id}.#{offer.id}", false, 1.hour) do
      width = 320
      height = 50
      border = 2
      
      publisher_icon_blob = Downloader.get("http://s3.amazonaws.com/tapjoy/icons/#{publisher.id}.png")
      offer_icon_blob = Downloader.get("http://s3.amazonaws.com/tapjoy/icons/#{offer.id}.png")

      icon_height = height - border * 2 - 2
      publisher_icon = Magick::Image.from_blob(publisher_icon_blob)[0].resize(icon_height, icon_height)
      offer_icon = Magick::Image.from_blob(offer_icon_blob)[0].resize(icon_height, icon_height)

      publisher_icon = publisher_icon.vignette(-5, -5, 10, 2)
      offer_icon = offer_icon.vignette(-5, -5, 10, 2)

      img = Magick::Image.new(width - border * 2, height - border * 2)
      img.format = 'png'

      img.composite!(publisher_icon, 1, 1, Magick::AtopCompositeOp)
      img.composite!(offer_icon, width - icon_height - 5, 1, Magick::AtopCompositeOp)

      text = "Earn #{publisher.primary_currency.get_reward_amount(offer)} #{publisher.primary_currency.name} in #{publisher.name}!\n Install #{offer.name}"
      image_label = Magick::Image.read("label:#{text}") do
        self.size = "220x44"
        self.gravity = Magick::CenterGravity
        self.stroke = 'transparent'
        self.background_color = 'transparent'
      end
      img.composite!(image_label[0], 40, 0, Magick::AtopCompositeOp)

      free_label = Magick::Image.read("label:F\nR\nE\nE") do
        self.size = "8x44"
        self.gravity = Magick::CenterGravity
        self.stroke = 'transparent'
        self.fill = 'white'
        self.undercolor = 'red'
        self.background_color = 'red'
      end
      img.composite!(free_label[0], 262, 1, Magick::AtopCompositeOp)

      img.border!(border, border, 'black')
      
      Base64.encode64(img.to_blob).gsub("\n", '')
    end
  end
  
  def get_user_id_from_udid(udid, app_id)
    case app_id
    when "9dfa6164-9449-463f-acc4-7a7c6d7b5c81" # TapFish
      "TF:#{udid}"
    when "b91369a6-36bc-4ede-80e5-009f48466539" # Tap Birds
      "TB:#{udid}"
    when "0fd33f9d-5edf-4377-941c-3b93e5814f39" # Tap Ranch
      "TR:#{udid}"
    else
      udid
    end
  end
end