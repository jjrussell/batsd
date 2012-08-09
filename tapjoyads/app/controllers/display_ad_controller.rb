class DisplayAdController < ApplicationController

  before_filter :set_device_type, :lookup_udid, :set_publisher_user_id, :setup, :except => :image
  after_filter :queue_impression_tracking, :only => [:index, :webview]

  def index
    if @publisher_app.present? && !@publisher_app.uses_non_html_responses?
      @publisher_app.queue_update_attributes(:uses_non_html_responses => true)
    end
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
    return unless verify_params([:advertiser_app_id, :size, :publisher_app_id, :currency_id])
    offer_id = params[:advertiser_app_id]
    width, height = parse_size(params[:size])
    size = "#{width}x#{height}"

    key_options = params.slice(:currency_id, :display_multiplier).merge({:offer_id => offer_id, :width => width, :height => height})
    keys = [image_key_from_hash(key_options)]
    keys.unshift(image_key_from_hash(key_options.merge(:hash => params[:key]))) if params[:key].present?

    # always be up to date for previews
    Mc.distributed_delete(keys.first) if params[:publisher_app_id] == App::PREVIEW_PUBLISHER_APP_ID

    # if not found in cache, pass data required to generate
    image_data = image_from_cache(keys) do
      publisher = App.find_in_cache(params[:publisher_app_id])
      currency  = Currency.find_in_cache(params[:currency_id])
      currency  = nil if currency.present? && currency.app_id != params[:publisher_app_id]
      if params[:offer_type] == "TestOffer"
        offer = publisher.test_offer
      else
        offer = Offer.find_in_cache(offer_id)
      end

      return unless verify_records([publisher, currency, offer])
      generate_image({
        :publisher          => publisher,
        :currency           => currency,
        :offer              => offer,
        :width              => width,
        :height             => height,
        :display_multiplier => params[:display_multiplier] })
    end

    send_data Base64.decode64(image_data), :type => "image/png", :disposition => 'inline'
  end

  private

  def setup
    params[:currency_id] ||= params[:app_id]
    return unless verify_params([:app_id, :udid, :currency_id])

    now = Time.zone.now

    # For SDK version <= 8.2.2, use high-res (aka 2x) version of 320x50 ad
    # (except certain scenarios)
    if ((params[:size].blank? || (params[:size] == '320x50' &&
      params[:version].to_s.version_less_than_or_equal_to?('8.2.2'))) &&
      params[:action] != 'webview' && request.format != :json &&
      params[:app_id] != '6b69461a-949a-49ba-b612-94c8e7589642') # TextFree
        params[:size] = '640x100'
    end

    device = Device.new(:key => params[:udid])
    @publisher_app = App.find_in_cache(params[:app_id])
    currency = Currency.find_in_cache(params[:currency_id])
    currency = nil if currency.present? && currency.app_id != params[:app_id]

    return unless verify_records([@publisher_app, currency], :render_missing_text => false)

    params[:publisher_app_id] = @publisher_app.id
    params[:displayer_app_id] = @publisher_app.id
    params[:source] = 'display_ad'

    web_request = WebRequest.new(:time => now)
    web_request.put_values('display_ad_requested', params, ip_address, geoip_data, request.headers['User-Agent'])

    if currency.get_test_device_ids.include?(params[:udid])
      offer = @publisher_app.test_offer
    else
      offer = OfferList.new(
        :publisher_app       => @publisher_app,
        :device              => device,
        :currency            => currency,
        :device_type         => params[:device_type],
        :geoip_data          => geoip_data,
        :app_version         => params[:app_version],
        :os_version          => params[:os_version],
        :type                => Offer::DISPLAY_OFFER_TYPE,
        :source              => params[:source],
        :library_version     => params[:library_version],
        :screen_layout_size  => params[:screen_layout_size],
        :mobile_carrier_code => "#{params[:mobile_country_code]}.#{params[:mobile_network_code]}",
        :store_name          => params[:store_name]
      ).weighted_rand
    end

    if offer.present?
      @click_url = offer.click_url(
        :publisher_app     => @publisher_app,
        :publisher_user_id => params[:publisher_user_id],
        :udid              => params[:udid],
        :currency_id       => currency.id,
        :source            => 'display_ad',
        :viewed_at         => now,
        :displayer_app_id  => params[:app_id],
        :primary_country   => geoip_data[:primary_country],
        :mac_address       => params[:mac_address]
      )
      width, height = parse_size(params[:size])

      if params[:action] == 'webview' || params[:details] == '1'
        @image_url = offer.display_ad_image_url(:publisher_app_id => @publisher_app.id,
                                                :width => width,
                                                :height => height,
                                                :currency => currency,
                                                :display_multiplier => params[:display_multiplier])
      else
        @image = get_ad_image(@publisher_app, offer, width, height, currency, params[:display_multiplier])
      end

      @offer = offer
      if params[:details] == '1'
        @amount = currency.get_visual_reward_amount(offer, params[:display_multiplier])
        if offer.item_type == 'App'
          advertiser_app = App.find_in_cache(@offer.item_id)
          return unless verify_records([advertiser_app])
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
    options = { :currency           => currency.id,
                :offer              => offer.id,
                :width              => width,
                :height             => height,
                :display_multiplier => display_multiplier,
                :hash               => offer.display_ad_image_hash(currency)}
    key = image_key_from_hash(options)
    Mc.distributed_delete(key) if publisher.id == App::PREVIEW_PUBLISHER_APP_ID
    # if not found in cache, pass data required to generate
    image_from_cache(key) do
      generate_image({
        :publisher          => publisher,
        :currency           => currency,
        :offer              => offer,
        :width              => width,
        :height             => height,
        :display_multiplier => display_multiplier })
    end
  end

  ##
  # generate image data from objects
  def generate_image(data)
    offer              = data[:offer]
    size               = "#{data[:width]}x#{data[:height]}"
    currency           = data[:currency]
    display_multiplier = (data[:display_multiplier] || 1).to_f

    if offer.display_custom_banner_for_size?(size)
      key = offer.banner_creative_mc_key(size)
      Mc.distributed_delete(key) if data[:publisher].id == App::PREVIEW_PUBLISHER_APP_ID
      return Mc.distributed_get_and_put(key) do
        Base64.encode64(offer.banner_creative_s3_object(size).read).gsub("\n", '')
      end
    end

    if data[:width] == 640 && data[:height] == 100
      border = 4
      icon_padding = 7
      font_size = 26
      text_area_size = '380x92'
    elsif data[:width] == 768 && data[:height] == 90
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

    icon_height = data[:height] - border * 2 - icon_padding * 2

    bucket = S3.bucket(BucketNames::TAPJOY)
    background_blob = bucket.objects["display/self_ad_bg_#{data[:width]}x#{data[:height]}.png"].read
    background = Magick::Image.from_blob(background_blob)[0]

    img = Magick::Image.new(data[:width], data[:height])
    img.format = 'png'
    img.composite!(background, 0, 0, Magick::AtopCompositeOp)

    font = (Rails.env.production? || Rails.env.staging?) ? 'Arial-Unicode' : ''

    if (offer.rewarded? && currency.rewarded?) && offer.item_type != 'TestOffer'
      text = "Earn #{currency.get_visual_reward_amount(offer, display_multiplier)} #{currency.name}"
      text << ' download' if text.length <= 20
      text << "\n#{offer.name}"
    else
      text = offer.name
    end

    image_label = get_image_label(text, text_area_size, font_size, font, false)
    img.composite!(image_label[0], icon_height + icon_padding * 4 + 1, border + 2, Magick::AtopCompositeOp)
    image_label = get_image_label(text, text_area_size, font_size, font, true)
    img.composite!(image_label[0], icon_height + icon_padding * 4, border + 1, Magick::AtopCompositeOp)

    offer_icon_blob = offer.icon_s3_object.read rescue ''
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

  ##
  # Gets image from cache given a list of keys to try, generates image on failure from yielded data
  def image_from_cache(keys)
    Mc.distributed_get_and_put(keys, false, 1.day) do
      yield
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

  def queue_impression_tracking
    # for third party tracking vendors
    if @offer.present?
      @offer.queue_impression_tracking_requests(
        :ip_address       => ip_address,
        :udid             => params[:udid],
        :publisher_app_id => params[:app_id])
    end
  end

  ##
  # Returns the image cache key for the image optionaly including image hash,
  # only requires ids not objects
  def image_key_from_hash(options)
    display_multiplier = (options[:display_multiplier] || 1).to_f
    size = "#{options[:width]}x#{options[:height]}"
    key = "display_ad.#{options[:currency_id]}.#{options[:offer_id]}.#{size}.#{display_multiplier}"
    key << ".#{options[:hash]}" if options[:hash]
    key
  end
end
