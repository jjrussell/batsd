class UserEventsController < ApplicationController

  DEVICE_KEYS_TO_TRY = [ :udid, :mac_address, :android_id, :serial_id, :sha1_mac_address ]

  before_filter :setup, :only => [ :create ]

  def create
    begin
      event = UserEvent.new(@type, @event_data)
      event.put_values(nil, params, ip_address, geoip_data, request.headers['User-Agent'])
      event.save
      render :text => "#{I18n.t('user_event.success.created')}\n", :status => :ok
    rescue Exception => error
      render :text => "#{error.message}\n\n#{error.backtrace}\n", :status => :bad_request
    end
  end

  private

  def setup
    begin
      app = App.find_in_cache(params[:app_id])
      raise "App ID '#{params[:app_id]}' could not be found. Check 'app_id' and try again." unless app
      device_id_key = DEVICE_KEYS_TO_TRY.detect { |key| params[key].present? }
      raise I18n.t('user_event.error.no_device') unless device_id_key
      device = Device.find(params[device_id_key])
      event_type_id = params.delete(:event_type_id).to_i
      raise I18n.t('user_event.error.invalid_event_type') unless event_type_id > 0
      @type = UserEventTypes::EVENT_TYPE_KEYS[event_type_id]
      @event_data = params.delete(:ue).try(:symbolize_keys)
      remote_verifier = params.delete(:verifier)
      # raise I18n.t('user_event.error.no_verifier') unless remote_verifier.present?
      # local_verifier = UserEvent.verifier_string(app.id, device.id, app.secret_key, event_type_id, @event_data)
      # raise I18n.t('user_event.error.verification_failed') unless local_verifier == remote_verifier
    rescue Exception => error
      render :text => "#{error.message}\n", :status => :bad_request
    end
  end

end
