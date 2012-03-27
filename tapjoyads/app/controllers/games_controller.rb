class GamesController < ApplicationController
  include Facebooker2::Rails::Controller
  include SslRequirement

  layout :select_layout

  skip_before_filter :fix_params
  before_filter :setup_tjm_request
  after_filter :save_tjm_request

  helper_method :current_gamer, :set_gamer, :current_device_id, :current_device_id_cookie, :current_device, :current_recommendations, :has_multiple_devices, :show_login_page, :device_type, :geoip_data, :os_version, :social_feature_redirect_path, :get_friends_info

  protected

  def get_friends_info(ids)
    Gamer.find_all_by_id(ids).map do |friend|
      {
        :id        => friend.id,
        :name      => friend.get_gamer_name,
        :nickname  => friend.get_gamer_nickname,
        :image_url => friend.get_avatar_url
      }
    end
  end

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
    splits = []
    unset_priority = 2.0
    language_list = request.env['HTTP_ACCEPT_LANGUAGE'].split(/\s*,\s*/).map do |pair|
      language, quality = pair.split(/;q=/)
      raise "Not correctly formatted" unless language =~ /^[a-z\-]+$/i
      language = language.downcase.gsub(/-[a-z]+$/i) { |i| i.upcase }
      quality = unset_priority -= 0.1 unless quality.to_s =~ /\d+(\.\d+)?$/
      result = [ - quality.to_f, language ]
      splits << [ - (quality.to_f - 0.1), language.split(/-/).first ] if language =~ /-/
      result
    end
    language_list.concat splits
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
        flash[:error] = @error_msg || t('text.games.facebook_connect_failed')
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
      flash[:error] = @error_msg || t('text.games.please_connect_facebook')
      redirect_to social_feature_redirect_path
    end
  end

  def has_permissions?
    begin
      unless current_facebook_user.has_permission?(:offline_access) && current_facebook_user.has_permission?(:publish_stream)
        @error_msg = t('grant_permissions_for_invite')
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
      @error_msg = t('text.games.mogli_reach_limit_error')
    when Mogli::Client::HTTPException
      @error_msg = t('text.games.social_invite_friend_error')
    when Mogli::Client::SessionInvalidatedDueToPasswordChange, Mogli::Client::OAuthException
      @error_msg = t('text.games.social_need_authorize_error')
    else
      @error_msg = t('text.games.social_invite_friend_error')
    end

    dissociate_and_redirect
  end

  def handle_twitter_exceptions(e)
    case e
    when Twitter::Forbidden
      render :json => { :success => false, :error => t('text.games.twitter_forbidden_error') }
    when Twitter::Unauthorized
      current_gamer.dissociate_account!(Invitation::TWITTER)
      render :json => { :success => false, :errorRedirectPath => games_social_get_twitter_friends_path } and return if params[:ajax].present?
      redirect_to games_social_get_twitter_friends_path
    when Twitter::InternalServerError, Twitter::BadGateway, Twitter::ServiceUnavailable
      render :json => { :success => false, :error => t('text.games.twitter_internal_error') } and return if params[:ajax].present?
      flash[:error] = t('text.games.twitter_internal_error')
      redirect_to social_feature_redirect_path
    else
      render :json => { :success => false, :error => t('text.games.social_invite_friend_error') } and return if params[:ajax].present?
      flash[:error] = t('text.games.social_invite_friend_error')
      redirect_to social_feature_redirect_path
    end
  end

  def handle_errno_exceptions
    flash[:error] = t('text.games.errno_error')
    redirect_to social_feature_redirect_path
  end

  private

  def render_json_error(errors, status = 403)
    render(:json => { :success => false, :error => errors }, :status => status)
  end

  def current_gamer_session
    @current_gamer_session ||= GamerSession.find
  end

  def require_gamer
    unless current_gamer
      path = url_for(params.merge(:only_path => true))
      options = { :path => path } unless path == games_root_path
      options[:referrer] = params[:referrer] if params[:referrer].present?
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
    "#{WEBSITE_URL}#{games_social_index_path}"
  end

  def current_gamer
    @current_gamer ||= current_gamer_session && current_gamer_session.record
  end

  def current_device_id
    if session[:current_device_id]
      @current_device_id = ObjectEncryptor.decrypt(session[:current_device_id])
    end
    if @current_device_id.nil?
      device_id_cookie = current_device_id_cookie
      @current_device_id = device_id_cookie if device_id_cookie.present? && valid_device_id(device_id_cookie)
      @current_device_id ||= current_gamer.devices.first.device_id if current_gamer && current_gamer.devices.present?
      session[:current_device_id] = ObjectEncryptor.encrypt(@current_device_id) if @current_device_id.present?
    end
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

  def current_device
    return @current_device if @current_device
    if current_gamer && current_device_id
      @current_device = current_gamer.devices.find_by_device_id(current_device_id)
    end
  end

  def current_recommendations
    @recommendations ||= get_recommendations
  end

  def get_recommendations
    options = {
      :device_type => device_type,
      :geoip_data  => geoip_data,
      :os_version  => os_version,
    }
    device = Device.new(:key => current_device_id)
    device.recommendations(options)
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

  def select_layout
    if params[:ajax].present?
      nil
    else
      'marketplace'
    end
  end

  def setup_tjm_request
    now = Time.zone.now
    if tjm_session_expired?(now)
      session[:tjms_stime] = now.to_i
      session[:tjms_id]    = UUIDTools::UUID.random_create.hexdigest
    end

    tjm_request_options = {
      :time       => now,
      :session    => session,
      :request    => request,
      :ip_address => ip_address,
      :geoip_data => geoip_data,
      :params     => params,
      :gamer      => current_gamer,
      :device_id  => current_device_id,
    }
    @tjm_request = TjmRequest.new(tjm_request_options)

    session[:tjms_ltime] = now
  end

  def save_tjm_request
    @tjm_request.save if @tjm_request.present?
  end

  def tjm_session_expired?(now = Time.zone.now)
    session[:tjms_id].blank?    ||
    session[:tjms_stime].blank? ||
    session[:tjms_ltime].blank? ||
    Time.zone.at(session[:tjms_ltime].to_i) < now - TJM_SESSION_TIMEOUT
  end

end
