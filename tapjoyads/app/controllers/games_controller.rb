class GamesController < ApplicationController
  include Facebooker2::Rails::Controller
  include SslRequirement

  layout 'games'

  skip_before_filter :fix_params

  helper_method :current_gamer, :current_device_id, :current_device_id_cookie, :current_device_info, :has_multiple_devices

  def current_gamer
    @current_gamer ||= current_gamer_session && current_gamer_session.record
  end

  def current_device_id
    if session[:current_device_id]
      @current_device_id = SymmetricCrypto.decrypt_object(session[:current_device_id], SYMMETRIC_CRYPTO_SECRET)
    else
      device_id_cookie = current_device_id_cookie
      @current_device_id = device_id_cookie if device_id_cookie.present? && valid_device_id(device_id_cookie)
      @current_device_id ||= current_gamer.devices.first.device_id if current_gamer.devices.present?
    end
    session[:current_device_id] ||= SymmetricCrypto.encrypt_object(@current_device_id, SYMMETRIC_CRYPTO_SECRET)
    @current_device_id
  end

  def current_device_id_cookie
    if cookies[:data]
      begin
        cookie_data = SymmetricCrypto.decrypt_object(cookies[:data], SYMMETRIC_CRYPTO_SECRET)
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

protected

  def ssl_required?
    Rails.env == 'production'
  end

  def set_current_device(data)
    device_data = SymmetricCrypto.decrypt_object(data, SYMMETRIC_CRYPTO_SECRET)
    if valid_device_id(device_data[:udid])
      session[:current_device_id] = SymmetricCrypto.encrypt_object(device_data[:udid], SYMMETRIC_CRYPTO_SECRET)
      session[:current_device_id] ? SymmetricCrypto.decrypt_object(session[:current_device_id], SYMMETRIC_CRYPTO_SECRET) : nil
    end
  end

  def offline_facebook_authenticate
    if current_gamer.facebook_id.blank? && current_facebook_user
      begin
        current_gamer.gamer_profile.update_facebook_info!(current_facebook_user)
      rescue
        flash[:error] = @error_msg || 'Failed connecting to Facebook profile'
        redirect_to edit_games_gamer_path
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
      redirect_to edit_games_gamer_path
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
    redirect_to edit_games_gamer_path
  end

private

  def current_gamer_session
    @current_gamer_session ||= GamerSession.find
  end

  def valid_device_id(udid)
    current_gamer.devices.find_by_device_id(udid) if current_gamer
  end

end
