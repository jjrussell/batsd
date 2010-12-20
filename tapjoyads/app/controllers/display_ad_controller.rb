class DisplayAdController < ApplicationController
  
  # A hard-coded list of publisher apps that support ABC ads.
  @@allowed_publisher_app_ids = Set.new([
      # Brooklyn Packet Co.
      "41df65f0-593c-470b-83a4-37be66740f34", # Tap Resort
      "262294a6-0304-48d9-a6d0-e0b7bf60f345", # Tap Resport Party
      "bda9f852-0548-40c3-906e-f0b85709c6be", # Tap Galaxy
      "918bc82f-edc6-4ebe-b5d2-073f8484038d", # Tiny Chef
      
      # BayView Labs
      "9dfa6164-9449-463f-acc4-7a7c6d7b5c81", # TapFish
      "b91369a6-36bc-4ede-80e5-009f48466539", # Tap Birds
      "0fd33f9d-5edf-4377-941c-3b93e5814f39", # Tap Ranch
      
      # Streetview Labs
      "c3fc6075-57a9-41d1-b0ee-e1c0cbbe4ef3", # Tap Zoo
      "b23efaf0-b82b-4525-ad8c-4cd11b0aca91", # Tap Store
      
      # Get Set Games
      "d85f0eb8-2b78-4a41-b41c-d15e2407f115", # Mega Jump
      
      # Playforge
      "e26bd54e-a9ec-4f60-b84d-82b4f678343a", # Zombie Farm
      ])
  
  # List of apps that are "AB" advertisers; ie apps which advertise their own currency.
  @@banner_app_ids = Set.new([
      # Glu
      "0da90aad-b122-41b9-a0f9-fa849b6fbfbd", # Gun Bros
      "68788308-05c8-401f-9aba-f48b57a17f75", # Toyshop Adventures 
      "2cc8b4e6-e800-408d-9dd9-bd5fe969a9ce", # World Series of Poker
    
      # Pinger
      "3cb9aacb-f0e6-4894-90fe-789ea6b8361d", # Doodle Buddy
      
      # Tapjoy
      "2349536b-c810-47d7-836c-2cd47cd3a796", # TapDefense
      ])
  
  before_filter :setup, :except => :image
  
  def index
  end
  
  def webview
    if @click_url.present? && @image.present?
      unless params[:app_id] == "2349536b-c810-47d7-836c-2cd47cd3a796"
        # Ensure TapDefense is always https, so that AdMarvel can test their implementation
        # and ensure all other apps are always http, so that AdMarvel will work.
        @click_url.gsub!(/^https/, 'http') 
      end
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
    if @@banner_app_ids.include?(params[:app_id])
      publisher_app_ids << params[:app_id]
    else
      @@allowed_publisher_app_ids.each do |app_id|
        last_run_time = device.last_run_time(app_id)
        if last_run_time.present? && last_run_time > now - 1.week
          publisher_app_ids << app_id
        end
      end
    end
    
    if publisher_app_ids.present?
      publisher_app_id = publisher_app_ids[rand(publisher_app_ids.size)]
      publisher_app = App.find_in_cache(publisher_app_id)
      currency = Currency.find_in_cache(publisher_app_id)

      # Randomly choose a free offer that is converting at greater than 50%
      offer_list, more_data_available = publisher_app.get_offer_list(params[:udid],
          :device => device,
          :currency => currency,
          :device_type => params[:device_type],
          :geoip_data => geoip_data,
          :required_length => 25,
          :reject_rating_offer => true)

      displayer_currency = Currency.find_in_cache(params[:app_id]) rescue nil
      disabled_offer_ids = displayer_currency.nil? ? Set.new : displayer_currency.get_disabled_offer_ids
      disabled_partner_ids = displayer_currency.nil? ? Set.new : displayer_currency.get_disabled_partner_ids
    
      offer_list.reject! do |offer|
        offer.is_paid? || 
        offer.conversion_rate < 0.5 || 
        offer.item_id == params[:app_id] || 
        offer.name.size > 30 ||
        offer.item_type != "App" ||
        disabled_offer_ids.include?(offer.id) ||
        disabled_partner_ids.include?(offer.partner_id)
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
    
    # TO REMOVE - make sure there is always a display ad for Tap Colors!
    if params[:app_id] == '09913ef6-906c-47ed-bd05-567c91dfa7fd' && @click_url.nil?
      @click_url = "http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=297558390&mt=8"
      @image = get_tap_defense_ad
    end
    
    web_request.save
  end

  def get_ad_image(publisher, offer)
    
    Mc.get_and_put("display_ad.#{publisher.id}.#{offer.id}", false, 1.hour) do
      width = 320
      height = 50
      border = 2
      icon_height = height - border * 2 - 2
      
      text = "Earn #{publisher.primary_currency.get_reward_amount(offer)} #{publisher.primary_currency.name}"
      text += " in #{publisher.name}" unless @@banner_app_ids.include?(publisher.id)
      text += " to buy Towers" if publisher.id == "2349536b-c810-47d7-836c-2cd47cd3a796" # TapDefense
      text += "!\n Install #{offer.name}"
      
      offer_icon_blob = Downloader.get("http://s3.amazonaws.com/tapjoy/icons/#{offer.id}.png")
      offer_icon = Magick::Image.from_blob(offer_icon_blob)[0].resize(icon_height, icon_height)
      offer_icon = offer_icon.vignette(-5, -5, 10, 2)

      text_area_left_offset = 0
      text_area_size = "260x40"

      unless @@banner_app_ids.include?(publisher.id)
        publisher_icon_blob = Downloader.get("http://s3.amazonaws.com/tapjoy/icons/#{publisher.id}.png")
        publisher_icon = Magick::Image.from_blob(publisher_icon_blob)[0].resize(icon_height, icon_height)
        publisher_icon = publisher_icon.vignette(-5, -5, 10, 2)
        
        text_area_left_offset = 40
        text_area_size = "220x40"
      end

      img = Magick::Image.new(width - border * 2, height - border * 2)
      img.format = 'png'

      img.composite!(publisher_icon, 1, 1, Magick::AtopCompositeOp) unless @@banner_app_ids.include?(publisher.id)
      img.composite!(offer_icon, width - icon_height - 5, 1, Magick::AtopCompositeOp)

      image_label = Magick::Image.read("label:#{text}") do
        self.size = text_area_size
        self.gravity = Magick::CenterGravity
        self.stroke = 'transparent'
        self.background_color = 'transparent'
      end
      img.composite!(image_label[0], text_area_left_offset, 2, Magick::AtopCompositeOp)

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
  
  def get_tap_defense_ad
    Mc.distributed_get_and_put("display_ad.tap_defense", false, 1.hour) do
      width = 320
      height = 50
      border = 2
      icon_height = height - border * 2 - 2
      
      text = "Try TapDefense!\nA free tower defense game."
      
      offer_icon_blob = Downloader.get("http://s3.amazonaws.com/tapjoy/icons/2349536b-c810-47d7-836c-2cd47cd3a796.png")
      offer_icon = Magick::Image.from_blob(offer_icon_blob)[0].resize(icon_height, icon_height)
      offer_icon = offer_icon.vignette(-5, -5, 10, 2)

      text_area_left_offset = 0
      text_area_size = "260x40"

      img = Magick::Image.new(width - border * 2, height - border * 2)
      img.format = 'png'

      img.composite!(offer_icon, width - icon_height - 5, 1, Magick::AtopCompositeOp)

      image_label = Magick::Image.read("label:#{text}") do
        self.size = text_area_size
        self.gravity = Magick::CenterGravity
        self.stroke = 'transparent'
        self.background_color = 'transparent'
      end
      img.composite!(image_label[0], text_area_left_offset, 2, Magick::AtopCompositeOp)

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
end