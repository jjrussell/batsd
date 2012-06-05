class Games::HomepageController < GamesController
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Twitter::Error, :with => :handle_twitter_exceptions
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions
  before_filter :require_gamer, :except => [ :index, :tos, :privacy, :translations, :get_app, :earn, :help ]
  before_filter :set_show_nav_bar_quad_menu, :only => [ :get_app, :earn, :help ]
  before_filter :set_exclude_social_from_submenu, :only => [ :help ]
  before_filter :set_exclude_help_from_submenu, :only => [ :help ]

  prepend_before_filter :decrypt_data_param

  skip_before_filter :setup_tjm_request, :only => :translations

  def translations
    tmp = params[:filename]
    match = tmp.match(/(\w)\-(\w)/)
    params[:language_code]= match[1]
    params[:hash] = match[2]
    render "translations.js", :layout => false, :content_type => "application/javascript"
  end

  def record_click
    if params[:redirect_url].present?
      url = ObjectEncryptor.decrypt(params[:redirect_url])
      @tjm_request.outbound_click_url = url if @tjm_request
      redirect_to url
    end
  end

  def get_app
    @offer = Offer.find(params_id)
    @app = @offer.app
    @app_metadata = @app.primary_app_metadata
    @click_url = games_record_click_path( { :redirect_url => ObjectEncryptor.encrypt(@offer.url),
                                            :eid => ObjectEncryptor.encrypt(@app.id)})
    return unless @app_metadata
    app_reviews = @app_metadata.app_reviews.find_all_by_id(params[:app_review_id]) if params[:app_review_id].present?
    if app_reviews.blank?
      app_reviews = AppReview.where(:app_metadata_id => @app_metadata.id, :is_blank => false).includes(:author).paginate(:page => params[:app_reviews_page])
      app_reviews.reject! { |x| x.bury_by_author?(current_gamer && current_gamer.id) || x.text.blank? }
      review_authors_not_viewer =  app_reviews.map(&:author_id) - [current_gamer && current_gamer.id].compact
      rude_buried_list = Gamer.all(:conditions => ["id IN(?) ", review_authors_not_viewer], :select => "id, extra_attributes")
      rude_buried_ids = rude_buried_list.select { |x| (x.been_buried_count || 0) > Gamer::RUDE_BAN_LIMIT }.map(&:id)
      app_reviews.reject! { |x| rude_buried_ids.include? x.author_id }
    end
    @app_reviews = app_reviews.sort { |a, b| b.moderation_rating <=> a.moderation_rating }
    ar_ids = app_reviews.map &:id
    @viewer_flagged = current_gamer && current_gamer.bury_review_votes.find_all_by_app_review_id(ar_ids) || []
    @viewer_faved = current_gamer && current_gamer.helpful_review_votes.find_all_by_app_review_id(ar_ids) || []
  end

  def earn
    device_id = current_device_id || 'statz_test_udid'
    @device = Device.new(:key => device_id) if device_id.present?
    @app = App.find(params_id)
    @active_currency = @app.currencies.first
    @external_publisher = ExternalPublisher.new(@active_currency)
    return unless verify_records([ @active_currency, @device ])
    @app_metadata = @app.primary_app_metadata
    if @app_metadata
      @mark_as_favorite = !(current_gamer && current_gamer.favorite_apps.map(&:app_metadata_id).include?(@app_metadata.id))
    end
    respond_to do |f|
      f.html
      f.js { render :layout => false }
    end
  end

  def index
    unless current_gamer
      params[:path] = url_for(params.merge(:only_path => true))
      set_show_nav_bar_login_button
      render_login_page and return
    end
    set_show_nav_bar_quad_menu
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
    record_recommended_apps
  end

  def switch_device
    if params[:data].nil?
      redirect_to games_path
    elsif set_current_device(params[:data])
      cookies[:data] = { :value => params[:data], :expires => 1.year.from_now }
      redirect_to games_path(:switch => true)
    else
      redirect_to games_path(:switch => false)
    end
  end

  def tos
  end

  def privacy
  end

  def help
  end

  def send_device_link
    ios_link_url = "https://#{request.host}#{games_path}"
    GamesMailer.deliver_link_device(current_gamer, ios_link_url, GAMES_ANDROID_MARKET_URL )
    render(:json => { :success => true })
  end

  private

  def params_id
    if params[:eid].present?
      ObjectEncryptor.decrypt(params[:eid])
    elsif params[:id].present?
      params[:id]
    end
  end
end
