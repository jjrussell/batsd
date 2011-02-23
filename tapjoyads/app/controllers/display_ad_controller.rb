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
  
  before_filter :set_device_type, :setup, :except => :image
  
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
    
    publisher = App.find_in_cache(params[:publisher_app_id])
    currency = Currency.find_in_cache(params[:publisher_app_id])
    offer = Offer.find_in_cache(params[:advertiser_app_id])
    return unless verify_records([ publisher, currency, offer ])
    
    web_request = WebRequest.new
    web_request.put_values('display_ad_image', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    web_request.save
    
    self_ad = (params[:publisher_app_id] == params[:displayer_app_id])
    ad_image_base64 = get_ad_image(publisher, offer, self_ad, params[:size], currency)
    
    send_data Base64.decode64(ad_image_base64), :type => 'image/png', :disposition => 'inline'
  end
  
private

  def setup
    return unless verify_params([ :app_id, :udid ])

    now = Time.zone.now
    geoip_data = get_geoip_data
    geoip_data[:country] = params[:country_code] if params[:country_code].present?
    params[:displayer_app_id] = params[:app_id]
    
    if params[:publisher_user_id].blank?
      params[:publisher_user_id] = params[:udid]
    end
    
    web_request = WebRequest.new(:time => now)
    web_request.put_values('display_ad_requested', params, get_ip_address, geoip_data, request.headers['User-Agent'])
    
    if params[:size].blank? || params[:size] == '320x50'
      # Don't show high-res ads to AdMarvel, except a few test devices.
      # TO REMOVE: Once done testing high-res ads on AdMarvel
      if params[:action] != 'webview' || (params[:udid] == '8c1a93d64ed3b6c65717a5d56786cae58a500f9e' || params[:udid] == 'c1bd5bd17e35e00b828c605b6ae6bf283d9bafa1')
        # params[:size] = '640x100'
      end
    end
    
    displayer_currency = Currency.find_in_cache(params[:app_id])
    self_ad = (displayer_currency.present? && displayer_currency.banner_advertiser?)
    
    # Randomly choose one publisher app that the user has run:
    device = Device.new(:key => params[:udid])
    publisher_app_ids = []
    if self_ad
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
      return unless verify_records([ publisher_app, currency ])

      # Randomly choose a free App offer that is converting at greater than 50%
      offer_list, more_data_available = publisher_app.get_offer_list(params[:udid],
          :device => device,
          :currency => currency,
          :device_type => params[:device_type],
          :geoip_data => geoip_data,
          :required_length => 25,
          :type => Offer::DISPLAY_OFFER_TYPE)

      disabled_offer_ids = displayer_currency.nil? ? Set.new : displayer_currency.get_disabled_offer_ids
      disabled_partner_ids = displayer_currency.nil? ? Set.new : displayer_currency.get_disabled_partner_ids
    
      offer_list.reject! do |offer|
        offer.item_id == params[:app_id] ||
        offer.name.size > 30 ||
        disabled_offer_ids.include?(offer.id) ||
        disabled_partner_ids.include?(offer.partner_id)
      end
      srand
      offer = offer_list[rand(offer_list.size)]
    
      if offer.present?
        user_id = self_ad ? params[:publisher_user_id] : get_user_id_from_udid(params[:udid], publisher_app_id)
        @click_url = offer.get_click_url(
            :publisher_app     => publisher_app,
            :publisher_user_id => user_id,
            :udid              => params[:udid],
            :currency_id       => currency.id,
            :source            => 'display_ad',
            :viewed_at         => now,
            :displayer_app_id  => params[:app_id],
            :country_code      => geoip_data[:country]
        )
        @image = get_ad_image(publisher_app, offer, self_ad, params[:size], currency)
      
        params[:offer_id] = offer.id
        params[:publisher_app_id] = publisher_app.id
        
        web_request.add_path('display_ad_shown')
      end
    end
    
    web_request.save
  end

  def get_ad_image(publisher, offer, self_ad, size, currency)
    width, height = parse_size(size)
    
    if self_ad && ((width == 320 && height == 50) || (width == 640 && height == 100))
      return get_self_ad_image(publisher, offer, size, currency)
    end
    
    Mc.get_and_put("display_ad.#{publisher.id}.#{offer.id}.#{width}x#{height}", false, 1.hour) do
      border = 2
      icon_height = height - border * 2 - 2
      vignette_amount = icon_height < 50 ? -5 : -15
      free_width = icon_height < 50 ? 8 : 11
      
      text = "Earn #{currency.get_reward_amount(offer)} #{currency.name}"
      text += " in #{publisher.name}" unless self_ad
      text += " to buy Towers" if publisher.id == "2349536b-c810-47d7-836c-2cd47cd3a796" # TapDefense
      text += "!\n Install #{offer.name}"
      
      bucket = S3.bucket(BucketNames::TAPJOY)
      offer_icon_blob = bucket.get("icons/#{offer.icon_id}.png")
      offer_icon = Magick::Image.from_blob(offer_icon_blob)[0].resize(icon_height, icon_height)
      offer_icon = offer_icon.vignette(vignette_amount, vignette_amount, 10, 2)

      if self_ad
        text_area_left_offset = 1
        text_area_size = "#{width - icon_height - border * 2 - free_width - 4}x#{icon_height}"
      else self_ad
        publisher_icon_blob = bucket.get("icons/#{publisher.id}.png")
        publisher_icon = Magick::Image.from_blob(publisher_icon_blob)[0].resize(icon_height, icon_height)
        publisher_icon = publisher_icon.vignette(vignette_amount, vignette_amount, 10, 2)
        
        text_area_left_offset = 2 + icon_height
        text_area_size = "#{width - icon_height * 2 - border * 2 - free_width - 5}x#{icon_height}"
      end

      img = Magick::Image.new(width - border * 2, height - border * 2)
      img.format = 'png'

      img.composite!(publisher_icon, 1, 1, Magick::AtopCompositeOp) unless self_ad
      img.composite!(offer_icon, width - icon_height - 5, 1, Magick::AtopCompositeOp)

      image_label = Magick::Image.read("label:#{text}") do
        self.size = text_area_size
        self.gravity = Magick::CenterGravity
        self.stroke = 'transparent'
        self.background_color = 'transparent'
      end
      img.composite!(image_label[0], text_area_left_offset, 1, Magick::AtopCompositeOp)

      free_label = Magick::Image.read("label:F\nR\nE\nE") do
        self.size = "#{free_width}x#{icon_height}"
        self.gravity = Magick::WestGravity
        self.stroke = 'transparent'
        self.fill = 'white'
        self.undercolor = 'red'
        self.background_color = 'red'
      end
      img.composite!(free_label[0], width - icon_height - border - free_width - 4, 1, Magick::AtopCompositeOp)
      
      img.border!(border, border, 'black')
      
      Base64.encode64(img.to_blob).gsub("\n", '')
    end
  end
  
  def get_self_ad_image(publisher, offer, size, currency)
    width, height = parse_size(size)
    
    Mc.get_and_put("display_ad.#{publisher.id}.#{offer.id}.#{width}x#{height}", false, 1.hour) do
      if width > 600 
        border = 4
        icon_padding = 7
        font_size = 24
        text_area_size = '380x92'
      else
        border = 2
        icon_padding = 3
        font_size = 12
        text_area_size = '190x46'
      end
      icon_height = height - border * 2 - icon_padding * 2
    
      bucket = S3.bucket(BucketNames::TAPJOY)
      background_blob = bucket.get("display/self_ad_bg_#{width}x#{height}.png")
      background = Magick::Image.from_blob(background_blob)[0]
      
      offer_icon_blob = bucket.get("icons/medium/#{offer.icon_id}.jpg")
      offer_icon = Magick::Image.from_blob(offer_icon_blob)[0].resize(icon_height, icon_height)
      
      corner_mask_blob = bucket.get("display/round_mask.png")
      corner_mask = Magick::Image.from_blob(corner_mask_blob)[0].resize(icon_height, icon_height)
      offer_icon.composite!(corner_mask, 0, 0, Magick::CopyOpacityCompositeOp)
      
      icon_shadow_blob = bucket.get("display/icon_shadow.png")
      icon_shadow = Magick::Image.from_blob(icon_shadow_blob)[0].resize(icon_height + icon_padding, icon_height)
      
      img = Magick::Image.new(width, height)
      img.format = 'png'
      
      img.composite!(background, 0, 0, Magick::AtopCompositeOp)
      img.composite!(icon_shadow, border + 2, border + icon_padding * 2, Magick::AtopCompositeOp)
      img.composite!(offer_icon, border + icon_padding, border + icon_padding, Magick::AtopCompositeOp)
      
      text = "Earn #{currency.get_reward_amount(offer)} #{currency.name} download \\n#{offer.name}"
      font = Rails.env == 'production' ? 'Helvetica' : ''
      image_label = Magick::Image.read("caption:#{text}") do
        self.size = text_area_size
        self.gravity = Magick::WestGravity
        self.fill = '#363636'
        self.pointsize = font_size
        self.font = font
        self.stroke = 'transparent'
        self.background_color = 'transparent'
      end
      img.composite!(image_label[0], icon_height + icon_padding * 4 + 1, border + 2, Magick::AtopCompositeOp)
      
      image_label = Magick::Image.read("caption:#{text}") do
        self.size = text_area_size
        self.gravity = Magick::WestGravity
        self.fill = 'white'
        self.pointsize = font_size
        self.font = font
        self.stroke = 'transparent'
        self.background_color = 'transparent'
      end
      img.composite!(image_label[0], icon_height + icon_padding * 4, border + 1, Magick::AtopCompositeOp)
      
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
  
  ##
  # Parses the size param and returns a width, height couplet. Ensures that the values returned are
  # supported by the get_ad_image method.
  def parse_size(size)
    case size
    when /320x50/i
      [320, 50]
    when /640x100/i
      [640, 100]
    when /768x90/i
      [768, 90]
    else
      [320, 50]
    end
  end
  
  ##
  # Sets the device_type parameter from the device_ua param, which AdMarvel sends.
  def set_device_type
    if params[:device_type].blank? && params[:device_ua].present?
      params[:device_type] = case params[:device_ua]
      when /iphone;/i
        'iphone'
      when /ipod;/i
        'ipod'
      when /ipad;/i
        'ipad'
      when /android/i
        'android'
      else
        nil
      end
    end
  end
  
end
