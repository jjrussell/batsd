class DisplayAdController < ApplicationController
  
  before_filter :set_device_type, :setup, :except => :image
  
  def index
  end
  
  def webview
    if @click_url.present? && @image_url.present?
      render :layout => false
    else
      render :text => ''
    end
  end
  
  def image
    return unless verify_params([ :publisher_app_id, :advertiser_app_id, :size ])
    
    width, height = parse_size(params[:size])

    key = "display_ad.decoded.#{params[:publisher_app_id]}.#{params[:advertiser_app_id]}.#{width}x#{height}.#{params[:display_multiplier] || 1}"
    image_data = Mc.get_and_put(key, false, 5.minutes) do
      publisher = App.find_in_cache(params[:publisher_app_id])
      currency = Currency.find_in_cache(params[:publisher_app_id])
      offer = Offer.find_in_cache(params[:advertiser_app_id])
      return unless verify_records([ publisher, currency, offer ])

      ad_image_base64 = get_ad_image(publisher, offer, params[:size], currency, params[:display_multiplier])
      
      Base64.decode64(ad_image_base64)
    end
    
    send_data image_data, :type => 'image/png', :disposition => 'inline'
  end
  
private

  def setup
    return unless verify_params([ :app_id, :udid ])
    
    now = Time.zone.now
    geoip_data = get_geoip_data
    geoip_data[:country] = params[:country_code] if params[:country_code].present?
    
    if params[:publisher_user_id].blank?
      params[:publisher_user_id] = params[:udid]
    end

    if params[:size].blank? || params[:size] == '320x50'
      # Don't show high-res ads to AdMarvel or TextFree, unless they explicitly send a size param.
      unless params[:action] == 'webview' || request.format == :json || params[:app_id] == '6b69461a-949a-49ba-b612-94c8e7589642'
        params[:size] = '640x100'
      end
    end
    
    device = Device.new(:key => params[:udid])
    publisher_app = App.find_in_cache(params[:app_id])
    currency = Currency.find_in_cache(params[:app_id])
    return unless verify_records([ publisher_app, currency ], :render_missing_text => false)
    
    params[:publisher_app_id] = publisher_app.id
    params[:displayer_app_id] = publisher_app.id
    
    web_request = WebRequest.new(:time => now)
    web_request.put_values('display_ad_requested', params, get_ip_address, geoip_data, request.headers['User-Agent'])

    offer_list, more_data_available = publisher_app.get_offer_list(
        :device => device,
        :currency => currency,
        :device_type => params[:device_type],
        :geoip_data => geoip_data,
        :required_length => 25,
        :type => Offer::DISPLAY_OFFER_TYPE)

    offer = offer_list[rand(offer_list.size)]
  
    if offer.present?
      @click_url = offer.get_click_url(
          :publisher_app     => publisher_app,
          :publisher_user_id => params[:publisher_user_id],
          :udid              => params[:udid],
          :currency_id       => currency.id,
          :source            => 'display_ad',
          :viewed_at         => now,
          :displayer_app_id  => params[:app_id],
          :country_code      => geoip_data[:country]
      )
      if params[:action] == 'webview'
        @image_url = get_ad_image_url(publisher_app, offer, params[:size], params[:display_multiplier])
      else
        @image = get_ad_image(publisher_app, offer, params[:size], currency, params[:display_multiplier])
      end
    
      web_request.offer_id = offer.id
      web_request.add_path('display_ad_shown')
    end
    
    web_request.save
  end

  def get_ad_image_url(publisher_app, offer, size, display_multiplier)
    display_multiplier = (display_multiplier || 1).to_f
    width, height = parse_size(params[:size])
    # TO REMOVE: displayer_app_id param after rollout.
    "#{API_URL}/display_ad/image?publisher_app_id=#{publisher_app.id}&advertiser_app_id=#{offer.id}&displayer_app_id=#{publisher_app.id}&size=#{width}x#{height}&display_multiplier=#{display_multiplier}"
  end

  def get_ad_image(publisher, offer, size, currency, display_multiplier)
    display_multiplier = (display_multiplier || 1).to_f
    width, height = parse_size(size)
    key = "display_ad.#{publisher.id}.#{offer.id}.#{width}x#{height}.#{display_multiplier}"
    Mc.get_and_put(key, false, 1.hour) do
      if width == 640 && height == 100
        border = 4
        icon_padding = 7
        font_size = 26
        text_area_size = '380x92'
      elsif width == 768 && height == 90
        border = 4
        icon_padding = 7
        font_size = 26
        text_area_size = '518x82'
      else
        border = 2
        icon_padding = 3
        font_size = 13
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
      
      if currency.hide_rewarded_app_installs?
        text = "Try #{offer.name} today"
      else
        text = "Earn #{currency.get_visual_reward_amount(offer, display_multiplier)} #{currency.name} download \\n#{offer.name}"
      end
      
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
      when /windows/i
        'windows'
      else
        nil
      end
    end
  end
  
end
