class UserEventsController < ApplicationController

  before_filter :setup

  def create
    begin
      event = UserEvent.new(@type, @event_data)
      event.put_values(params, ip_address, geoip_data, request.headers['User-Agent'])
      event.save
      render :text => "#{I18n.t('user_event.success.created')}\n", :status => :ok
    rescue UserEvent::UserEventInvalid => error
      render :text => "#{error.message}\n", :status => :bad_request
    end
  end

  private

  def setup
    begin
      app = App.find_in_cache(params[:app_id])
      unless app
        error_msg_data = { :app_id => params[:app_id] }
        raise UserEvent::UserEventInvalid, I18n.t('user_event.error.invalid_app_id', error_msg_data)
      end

      event_type_id = params.delete(:event_type_id).to_i
      @type = UserEvent::EVENT_TYPE_KEYS[event_type_id]

      @event_data = params.delete(:ue).try(:symbolize_keys) || {}
      remote_verifier = params.delete(:verifier)
      # raise UserEventInvalid, I18n.t('user_event.error.no_verifier') unless remote_verifier.present?
      # local_verifier = UserEvent.generate_verifier_key(app.id, device.id, app.secret_key, event_type_id, @event_data)
      # raise UserEventInvalid, I18n.t('user_event.error.verification_failed') unless local_verifier == remote_verifier
    rescue UserEvent::UserEventInvalid => error
      render :text => "#{error.message}\n", :status => :bad_request
    end
  end

end
