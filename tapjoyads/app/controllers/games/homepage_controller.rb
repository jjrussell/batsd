class Games::HomepageController < GamesController
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Twitter::Error, :with => :handle_twitter_exceptions
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions
  before_filter :require_gamer, :except => [ :index, :tos, :privacy, :translations ]
  skip_before_filter :setup_tjm_request, :only => :translations

  def translations
    render "translations.js", :layout => false, :content_type => "application/javascript"
  end

  def get_app
    if params[:eid].present?
      app_id = ObjectEncryptor.decrypt(params[:eid])
    elsif params[:id].present?
      app_id = params[:id]
    end
    @offer = Offer.find_by_id(app_id)
    @app = @offer.app
    @app_metadata = @app.primary_app_metadata
    if @app_metadata
      @app_reviews = AppReview.by_gamers.paginate_all_by_app_metadata_id(@app_metadata.id, :page => params[:app_reviews_page])
    end
  end

  def earn
    device_id = current_device_id
    @device = Device.new(:key => device_id) if device_id.present?
    if params[:eid].present?
      currency_id = ObjectEncryptor.decrypt(params[:eid])
    elsif params[:id].present?
      currency_id = params[:id]
    end
    @active_currency = Currency.find_by_id(currency_id)
    @external_publisher = ExternalPublisher.new(@active_currency)
    return unless verify_records([ @active_currency, @device ])

    @offerwall_url = @external_publisher.get_offerwall_url(@device, @external_publisher.currencies.first, request.accept_language, request.user_agent, current_gamer.id)
    @app = App.find_by_id(@external_publisher.app_id)
    @app_metadata = @app.primary_app_metadata
    if @app_metadata
      @mark_as_favorite = !current_gamer.favorite_apps.map(&:app_metadata_id).include?(@app_metadata.id)
    end

    respond_to do |f|
      f.html
      f.js { render :layout => false }
    end
  end

  def index
    unless current_gamer
      params[:path] = url_for(params.merge(:only_path => true))
      render_login_page and return
    end

    @require_select_device = current_device_id_cookie.nil?
    device_id = current_device_id
    @gamer = current_gamer
    @gamer.gamer_profile ||= GamerProfile.new(:gamer => @gamer)

    @device_name = current_device.name if current_device
    @device = Device.new(:key => device_id) if device_id.present?
    if @device.present?
      favorite_app_metadata_ids = current_gamer.favorite_apps.map(&:app_metadata_id)
      @external_publishers = ExternalPublisher.load_all_for_device(@device)
      @favorite_publishers = @external_publishers.select { |e| favorite_app_metadata_ids.include?(e.app_metadata_id) }

      @geoip_data = geoip_data
      platform = current_device ? current_device.device_type : ''
      featured_contents = FeaturedContent.with_country_targeting(@geoip_data, @device, platform)
      @featured_content = featured_contents.weighted_rand(featured_contents.map(&:weight))
      if @featured_content && @featured_content.tracking_offer
        @publisher_app       = App.find_in_cache(TRACKING_OFFER_CURRENCY_ID)
        params[:udid]        = @device.id
        @currency            = Currency.find_in_cache(TRACKING_OFFER_CURRENCY_ID)
        params[:source]      = 'tj_games'
        @now                 = Time.zone.now
        params[:device_name] = @device_name
        params[:gamer_id]    = current_gamer.id
      end
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
  end

  def send_device_link
    ios_link_url = "https://#{request.host}#{games_root_path}"
    GamesMailer.deliver_link_device(current_gamer, ios_link_url, GAMES_ANDROID_MARKET_URL )
    render(:json => { :success => true })
  end

  def record_local_request
    decrypt_data_param
    @tjm_request.is_ajax = true
    @tjm_request.controller = params[:request_controller] if params[:request_controller].present?
    @tjm_request.action = params[:request_action] if params[:request_action].present?

    if params[:request_path].present?
      @tjm_request.replace_path(params[:request_path])
    elsif params[:request_url].present?
      begin
        path = ActionController::Routing::Routes.recognize_path(params[:request_url])
        @tjm_request.controller = path[:controller]
        @tjm_request.action = path[:action]
        @tjm_request.update_path
      rescue ActionController::RoutingError
        render_json_error(['unable to find corresponding controller/action'], status = 400) and return
      end
    else
      render_json_error(['please provide either the request_path or request_url'], status = 400) and return
    end
    render(:json => { :success => true }, :status => 200)
  end
end
