class Games::HomepageController < GamesController

  before_filter :require_gamer, :except => [ :index, :tos, :privacy ]

  def index
    unless current_gamer
      params[:path] = url_for(params.merge(:only_path => true))
      render_login_page and return
    end

    if has_multiple_devices?
      @device_data = current_gamer.devices.map(&:device_data)
      @require_select_device = current_device_id_cookie.nil?
    end
    device_id = current_device_id
    device_info = current_device_info
    @device_name = device_info.name if device_info
    @device = Device.new(:key => device_id) if device_id.present?
    if @device.present?
      if params[:load] == 'earn'
        currency = Currency.find_by_id(params[:currency_id])
        @show_offerwall = @device.has_app?(currency.app_id) if currency
        @offerwall_external_publisher = ExternalPublisher.new(currency) if @show_offerwall
      end
      @external_publishers = ExternalPublisher.load_all_for_device(@device)
    end
    @featured_review = AppReview.featured_review(@device.try(:platform))

    if params[:action] == 'more_apps'
      @show_more_apps = true
      @editors_picks = EditorsPick.cached_active(using_android? ? 'android' : 'iphone')
      @more_app_offerwall = render_to_string :template => 'games/more_games/editor_picks', :layout => false
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
    render(:json => { :success => true }) and return
  end
end
