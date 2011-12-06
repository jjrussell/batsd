class DisplayAdController < ApplicationController

  before_filter :set_device_type, :set_publisher_user_id, :setup, :except => :image

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
    params[:currency_id] = params[:publisher_app_id] if params[:currency_id].blank?
    return unless verify_params([ :advertiser_app_id, :size, :publisher_app_id, :currency_id ])
    width, height = parse_size(params[:size])
    size = "#{width}x#{height}"

    key = "display_ad.decoded.#{params[:currency_id]}.#{params[:advertiser_app_id]}.#{size}.#{params[:display_multiplier] || 1}"

    # always be up to date for previews
    Mc.delete(key) if params[:publisher_app_id] == App::PREVIEW_PUBLISHER_APP_ID

    image_data = Mc.get_and_put(key, false, 5.minutes) do
      publisher = App.find_in_cache(params[:publisher_app_id])
      currency = Currency.find_in_cache(params[:currency_id])
      currency = nil if currency.present? && currency.app_id != params[:publisher_app_id]
      if params[:offer_type] == "TestOffer"
        offer = build_test_offer(publisher)
      else
        offer = Offer.find_in_cache(params[:advertiser_app_id])
      end
      return unless verify_records([ publisher, currency, offer ])

      ad_image_base64 = get_ad_image(publisher, offer, width, height, currency, params[:display_multiplier])

      Base64.decode64(ad_image_base64)
    end

    send_data image_data, :type => "image/png", :disposition => 'inline'
  end

  private

  def setup
    params[:currency_id] ||= params[:app_id]
    return unless verify_params([ :app_id, :udid, :currency_id ])

    now = Time.zone.now
    geoip_data = get_geoip_data
    geoip_data[:country] = params[:country_code] if params[:country_code].present?

    if params[:size].blank? || params[:size] == '320x50'
      # Don't show high-res ads to AdMarvel or TextFree, unless they explicitly send a size param.
      unless params[:action] == 'webview' || request.format == :json || params[:app_id] == '6b69461a-949a-49ba-b612-94c8e7589642'
        params[:size] = '640x100'
      end
    end

    device = Device.new(:key => params[:udid])
    publisher_app = App.find_in_cache(params[:app_id])
    currency = Currency.find_in_cache(params[:currency_id])
    currency = nil if currency.present? && currency.app_id != params[:app_id]
    return unless verify_records([ publisher_app, currency ], :render_missing_text => false)

    params[:publisher_app_id] = publisher_app.id
    params[:displayer_app_id] = publisher_app.id

    web_request = WebRequest.new(:time => now)
    web_request.put_values('display_ad_requested', params, get_ip_address, geoip_data, request.headers['User-Agent'])

    if currency.get_test_device_ids.include?(params[:udid])
      offer = build_test_offer(publisher_app)
    else
      offer = OfferList.new(
        :publisher_app      => publisher_app,
        :device             => device,
        :currency           => currency,
        :device_type        => params[:device_type],
        :geoip_data         => geoip_data,
        :os_version         => params[:os_version],
        :type               => Offer::DISPLAY_OFFER_TYPE,
        :library_version    => params[:library_version],
        :screen_layout_size => params[:screen_layout_size]
      ).weighted_rand
    end

    if offer.present?
      @click_url = offer.click_url(
        :publisher_app     => publisher_app,
        :publisher_user_id => params[:publisher_user_id],
        :udid              => params[:udid],
        :currency_id       => currency.id,
        :source            => 'display_ad',
        :viewed_at         => now,
        :displayer_app_id  => params[:app_id],
        :country_code      => geoip_data[:country]
      )
      width, height = parse_size(params[:size])

      if params[:action] == 'webview' || params[:details] == '1'
        @image_url = offer.display_ad_image_url(publisher_app.id, width, height, currency.id, params[:display_multiplier])
      else
        @image = get_ad_image(publisher_app, offer, width, height, currency, params[:display_multiplier])
      end

      if params[:details] == '1'
        @offer = offer
        @amount = currency.get_visual_reward_amount(offer, params[:display_multiplier])
        if offer.item_type == 'App'
          advertiser_app = App.find_in_cache(@offer.item_id)
          return unless verify_records([ advertiser_app ])
          @categories = advertiser_app.categories
        else
          @categories = []
        end
      end

      web_request.offer_id = offer.id
      web_request.path = 'display_ad_shown'
    end

    web_request.save
  end

  def get_ad_image(publisher, offer, width, height, currency, display_multiplier)
    display_multiplier = (display_multiplier || 1).to_f
    size = "#{width}x#{height}"

    if offer.display_custom_banner_for_size?(size)
      key = offer.banner_creative_mc_key(size)
      Mc.delete(key) if publisher.id == App::PREVIEW_PUBLISHER_APP_ID
      return Mc.get_and_put(key) do
        Base64.encode64(offer.banner_creative_s3_object(size).read).gsub("\n", '')
      end
    end

    key = "display_ad.#{currency.id}.#{offer.id}.#{size}.#{display_multiplier}"
    Mc.delete(key) if publisher.id == App::PREVIEW_PUBLISHER_APP_ID
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
      background_blob = bucket.objects["display/self_ad_bg_#{width}x#{height}.png"].read
      background = Magick::Image.from_blob(background_blob)[0]

      img = Magick::Image.new(width, height)
      img.format = 'png'
      img.composite!(background, 0, 0, Magick::AtopCompositeOp)

      font = (Rails.env.production? || Rails.env.staging?) ? 'Helvetica' : ''
      
      if offer.item_type == 'TestOffer'
        text = offer.name
      elsif offer.rewarded?
        text = "Earn #{currency.get_visual_reward_amount(offer, display_multiplier)} #{currency.name} download \\n#{offer.name}"
      else
        text = "Try #{offer.name} today"
      end
      
      image_label = get_image_label(text, text_area_size, font_size, font, false)
      img.composite!(image_label[0], icon_height + icon_padding * 4 + 1, border + 2, Magick::AtopCompositeOp)
      image_label = get_image_label(text, text_area_size, font_size, font, true)
      img.composite!(image_label[0], icon_height + icon_padding * 4, border + 1, Magick::AtopCompositeOp)

      offer_icon_blob = bucket.objects["icons/src/#{Offer.hashed_icon_id(offer.icon_id)}.jpg"].read rescue ''
      if offer_icon_blob.present?
        offer_icon = Magick::Image.from_blob(offer_icon_blob)[0].resize(icon_height, icon_height)
        corner_mask_blob = bucket.objects["display/round_mask.png"].read
        corner_mask = Magick::Image.from_blob(corner_mask_blob)[0].resize(icon_height, icon_height)
        offer_icon.composite!(corner_mask, 0, 0, Magick::CopyOpacityCompositeOp)
        
        icon_shadow_blob = bucket.objects["display/icon_shadow.png"].read
        icon_shadow = Magick::Image.from_blob(icon_shadow_blob)[0].resize(icon_height + icon_padding, icon_height)
      
        img.composite!(icon_shadow, border + 2, border + icon_padding * 2, Magick::AtopCompositeOp)
        img.composite!(offer_icon, border + icon_padding, border + icon_padding, Magick::AtopCompositeOp)
      end
      Base64.encode64(img.to_blob).gsub("\n", '')
    end
  end

  ##
  # Sets up image label for the ad image
  def get_image_label(text, text_area_size, font_size, font, use_white_fill)
    image_label = Magick::Image.read("caption:#{text}") do
      self.size = text_area_size
      self.gravity = Magick::WestGravity
      use_white_fill ? self.fill = 'white' : self.fill = '#363636'
      self.pointsize = font_size
      self.font = font
      self.stroke = 'transparent'
      self.background_color = 'transparent'
    end
    image_label
  end

  ##
  # Parses the size param and returns a width, height couplet. Ensures that the values returned are
  # supported by the get_ad_image method.
  def parse_size(size)
    size &&= size.downcase
    dimensions = Offer::DISPLAY_AD_SIZES.include?(size) ? size.split("x").collect{|x|x.to_i} : [320, 50]
  end

  ##
  # Sets the device_type parameter from the device_ua param, which AdMarvel sends.
  def set_device_type
    if params[:device_type].blank? && params[:device_ua].present?
      params[:device_type] = HeaderParser.device_type(params[:device_ua])
    end
  end

end
