class GamesController < ApplicationController
  include Facebooker2::Rails::Controller
  include SslRequirement

  layout 'games'

  skip_before_filter :fix_params

  helper_method :current_gamer, :current_device_id, :current_device_id_cookie, :current_device_info, :has_multiple_devices, :show_login_page, :device_type, :geoip_data, :os_version

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

  def has_multiple_devices?
    current_gamer.devices.size > 1
  end

  def device_type
    @device_type ||= HeaderParser.device_type(request.user_agent)
  end

  def os_version
    @os_version ||= HeaderParser.os_version(request.user_agent)
  end

  protected

  def ssl_required?
    Rails.env.production?
  end

  def set_current_device(data)
    device_data = ObjectEncryptor.decrypt(data)
    if valid_device_id(device_data[:udid])
      session[:current_device_id] = ObjectEncryptor.encrypt(device_data[:udid])
      session[:current_device_id] ? ObjectEncryptor.decrypt(session[:current_device_id]) : nil
    end
  end

  def valid_device_id(udid)
    current_gamer.devices.find_by_device_id(udid) if current_gamer
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
      return device.device_type == 'android'
    end

    HeaderParser.device_type(request.user_agent) == 'android'
  end
end
