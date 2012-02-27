class Games::HomepageController < GamesController
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions
  before_filter :require_gamer, :except => [ :index, :tos, :privacy, :translations ]

  def translations
    render "translations.js", :layout => false, :content_type=>"application/javascript"
  end

  def get_app
    @offer = Offer.find_by_id(params[:id])
    @app = @offer.app
    @app_metadata = @app.primary_app_metadata
    @app_reviews = AppReview.by_gamers.paginate_all_by_app_metadata_id(@app_metadata.id, :page => params[:app_reviews_page])
  end

  def review_app
  end

  def earn
    device_id = current_device_id
    @device = Device.new(:key => device_id) if device_id.present?
    if params[:eid].present?
      @curr_id = ObjectEncryptor.decrypt(params[:eid])
    elsif params[:id].present?
      @curr_id = params[:id]
    end
    @currency = Currency.find_by_id(@curr_id)
    @external_publisher = ExternalPublisher.new(@currency)
    @offerwall_url = @external_publisher.get_offerwall_url(@device, @external_publisher.currencies.first, request.accept_language, request.user_agent, current_gamer.id)
    @app_metadata_id = App.find_by_id(@external_publisher.app_id).primary_app_metadata.id

    respond_to do |f|
      f.html { render }
      f.js { render :layout => false }
    end
  end

  def my_apps
    device_id = current_device_id
    @device = Device.new(:key => device_id) if device_id.present?
    if @device.present?
      @external_publishers = ExternalPublisher.load_all_for_device(@device)
      if params[:load] == 'earn'
        currency = Currency.find_by_id(params[:currency_id])
        @show_offerwall = @device.has_app?(currency.app_id) if currency
        @offerwall_external_publisher = ExternalPublisher.new(currency) if @show_offerwall
      end
    end

    respond_to do |f|
      f.html { render }
      f.js { render :layout => false and return }
    end
  end

  def index
    unless current_gamer
      params[:path] = url_for(params.merge(:only_path => true))
      render_login_page and return
    end

    @device_data = current_gamer.devices.map(&:device_data)
    @require_select_device = current_device_id_cookie.nil?
    device_id = current_device_id
    device_info = current_device_info
    @gamer = current_gamer
    @gamer.gamer_profile ||= GamerProfile.new(:gamer => @gamer)

    @device_name = device_info.name if device_info
    @device = Device.new(:key => device_id) if device_id.present?
    if @device.present?
      @external_publishers = ExternalPublisher.load_all_for_device(@device)
      if params[:load] == 'earn'
        currency = Currency.find_by_id(params[:currency_id])
        @show_offerwall = @device.has_app?(currency.app_id) if currency
        @offerwall_external_publisher = ExternalPublisher.new(currency) if @show_offerwall
      end
      @geoip_data = geoip_data
      featured_contents = FeaturedContent.with_country_targeting(@geoip_data, @device)
      @featured_content = featured_contents.weighted_rand(featured_contents.map(&:weight))
      if @featured_content && @featured_content.tracking_offer
        @publisher_app       = @featured_content.tracking_offer.item
        params[:udid]        = @device.id
        @currency            = Currency.find_by_id(TRACKING_OFFER_CURRENCY_ID)
        params[:source]      = 'tj_games'
        @now                 = Time.zone.now
        params[:device_name] = @device_name
        params[:gamer_id]    = current_gamer.id
      end
    end

    if params[:load] == 'more_apps'
      @show_more_apps = true
      current_recommendations
    end
  end


  def switch_device
    if params[:data].nil?
      redirect_to games_root_path
    elsif set_current_device(params[:data])
      cookies[:data] = { :value => params[:data], :expires => 1.year.from_now }
      redirect_to games_root_path(:switch => true)
    else
      redirect_to games_root_path(:switch => false)
    end
  end

  def tos
  end

  def privacy
  end

  def help
    @gamer = current_gamer
  end

  def send_device_link
    ios_link_url = "https://#{request.host}#{games_root_path}"
    GamesMailer.deliver_link_device(current_gamer, ios_link_url, GAMES_ANDROID_MARKET_URL )
    render(:json => { :success => true }) and return
  end
end
