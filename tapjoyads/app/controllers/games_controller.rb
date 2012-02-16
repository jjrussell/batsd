class GamesController < ApplicationController
  include Facebooker2::Rails::Controller
  include SslRequirement

  layout 'games'

  skip_before_filter :fix_params
  before_filter :setup_tjm_request
  after_filter :save_tjm_request

  helper_method :current_gamer, :current_device_id, :current_device_id_cookie, :current_device_info, :current_recommendations, :has_multiple_devices, :show_login_page, :device_type, :geoip_data, :os_version, :social_feature_redirect_path

  protected

  def ssl_required?
    Rails.env.production?
  end

  def set_locale
    I18n.locale = (get_language_codes.concat(http_accept_language) & AVAILABLE_LOCALES_ARRAY).first
  end

  def get_language_codes
    return [] unless params[:language_code]

    code = params[:language_code]

    [ code, code.split(/-/).first ].uniq
  end

  def http_accept_language
    # example env[HTTP_ACCEPT_LANGUAGE] string: en,en-US;q=0.8,es;q=0.6,zh;q=0.4
    language_list = request.env['HTTP_ACCEPT_LANGUAGE'].split(/\s*,\s*/).map do |pair|
      language, quality = pair.split(/;q=/)
      raise "Not correctly formatted" unless language =~ /^[a-z\-]+$/i
      language = language.downcase.gsub(/-[a-z]+$/i) { |i| i.upcase }
      quality = 1.0 unless quality.to_s =~ /\d+(\.\d+)?$/
      [ - quality.to_f, language ]
    end
    language_list.sort.map(&:last)
  rescue # default if header is malformed
    []
  end
  def set_current_device(data)
    device_data = ObjectEncryptor.decrypt(data)
    if valid_device_id(device_data[:udid])
      session[:current_device_id] = ObjectEncryptor.encrypt(device_data[:udid])
      session[:current_device_id] ? ObjectEncryptor.decrypt(session[:current_device_id]) : nil
    end
  end

  def offline_facebook_authenticate
    if current_gamer.facebook_id.blank? && current_facebook_user
      begin
        current_gamer.gamer_profile.update_facebook_info!(current_facebook_user)
      rescue
        flash[:error] = @error_msg || 'Failed connecting to Facebook profile'
        redirect_to social_feature_redirect_path
      end
      unless has_permissions?
        dissociate_and_redirect
      end
    elsif current_gamer.facebook_id?
      fb_create_user_and_client(current_gamer.fb_access_token, '', current_gamer.facebook_id)
      unless has_permissions?
        dissociate_and_redirect
      end
    else
      flash[:error] = @error_msg ||'Please connect Facebook with Tapjoy.'
      redirect_to social_feature_redirect_path
    end
  end

  def has_permissions?
    begin
      unless current_facebook_user.has_permission?(:offline_access) && current_facebook_user.has_permission?(:publish_stream)
        @error_msg = "Please grant us both permissions before sending out an invite."
      end
    rescue
    end
    @error_msg.blank?
  end

  def dissociate_and_redirect
    current_gamer.gamer_profile.dissociate_account!(Invitation::FACEBOOK)
    render :json => { :success => false, :error_redirect => true } and return if params[:ajax].present?
    flash[:error] = @error_msg
    redirect_to social_feature_redirect_path
  end

  def valid_device_id(udid)
    current_gamer.devices.find_by_device_id(udid) if current_gamer
  end

  def handle_mogli_exceptions(e)
    case e
    when Mogli::Client::FeedActionRequestLimitExceeded
      @error_msg = "You've reached the limit. Please try again later."
    when Mogli::Client::HTTPException
      @error_msg = "There was an issue with inviting your friend. Please try again later."
    when Mogli::Client::SessionInvalidatedDueToPasswordChange, Mogli::Client::OAuthException
      @error_msg = "Please authorize us before sending out an invite."
    else
      @error_msg = "There was an issue with inviting your friend. Please try again later."
    end

    dissociate_and_redirect
  end

  def handle_errno_exceptions
    flash[:error] = "There was a connection issue. Please try again later."
    redirect_to social_feature_redirect_path
  end

  private

  def current_gamer_session
    @current_gamer_session ||= GamerSession.find
  end

  def require_gamer
    unless current_gamer
      path = url_for(params.merge(:only_path => true))
      options = { :path => path } unless path == games_root_path
      redirect_to games_login_path(options)
    end
  end

  def render_login_page
    @gamer_session ||= GamerSession.new
    @gamer ||= Gamer.new
    render 'games/gamer_sessions/new'
  end

  def using_android?
    if current_gamer && current_device_id
      device = GamerDevice.find_by_gamer_id_and_device_id(current_gamer.id, current_device_id)
      return device && device.device_type == 'android'
    end

    HeaderParser.device_type(request.user_agent) == 'android'
  end

  def social_feature_redirect_path
    return request.env['HTTP_REFERER'] if request.env['HTTP_REFERER']
    "#{WEBSITE_URL}#{edit_games_gamer_path}"
  end

  def current_gamer
    @current_gamer ||= current_gamer_session && current_gamer_session.record
  end

  def current_device_id
    if session[:current_device_id]
      @current_device_id = ObjectEncryptor.decrypt(session[:current_device_id])
    else
      device_id_cookie = current_device_id_cookie
      @current_device_id = device_id_cookie if device_id_cookie.present? && valid_device_id(device_id_cookie)
      @current_device_id ||= current_gamer.devices.first.device_id if current_gamer.devices.present?
    end
    session[:current_device_id] ||= ObjectEncryptor.encrypt(@current_device_id)
    @current_device_id
  end

  def current_device_id_cookie
    if cookies[:data]
      begin
        cookie_data = ObjectEncryptor.decrypt(cookies[:data])
        cookie_data[:udid]
      rescue
        nil
      end
    end
  end

  def current_device_info
    current_gamer.devices.find_by_device_id(current_device_id) if current_gamer
  end

  def current_recommendations
    @recommendations ||= Device.new(:key => current_device_id).recommendations(:device_type => device_type, :geoip_data => get_geoip_data, :os_version => os_version)
  end

  def has_multiple_devices?
    current_gamer.devices.size > 1
  end

  def device_type
    @device_type ||= HeaderParser.device_type(request.user_agent)
  end

  def os_version
    @os_version ||= HeaderParser.os_version(request.user_agent)
  end

  def setup_tjm_request
    now = Time.now.utc
    if session[:tjm_session_id].blank? || session[:tjm_session_started_at].blank? || session[:tjm_session_last_active_at].blank? ||
        session[:tjm_session_last_active_at] < now - TJM_SESSION_TIMEOUT
      session[:tjm_session_started_at] = now
      session[:tjm_session_id] = UUIDTools::UUID.random_create.hexdigest
    end
    session[:tjm_session_last_active_at] = now

    @tjm_request = TjmRequest.new(:time => now)
    @tjm_request.add_standard_attributes(session, request, current_gamer, current_device_id, get_ip_address, get_geoip_data, params)
  end

  def save_tjm_request
    @tjm_request.save
  end

end
