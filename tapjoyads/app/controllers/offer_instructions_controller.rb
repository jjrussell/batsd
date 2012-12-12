class OfferInstructionsController < ApplicationController
  prepend_before_filter :decrypt_data_param
  after_filter :save_web_request, :only => [:index]

  layout :instructions_layout

  def index
    return unless verify_params([ :data, :id, :publisher_app_id, :udid ])
    @offer = Offer.find_in_cache(params[:id])
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    return unless verify_records([ @offer, @currency ])

    @device_type = params[:device_type]

    if @offer.item_type == 'ActionOffer' && (@action_app = App.find_in_cache(@offer.action_offer_app_id))
      params.delete(:data)
      params[:action_app_id] = @action_app.id
      params[:data] = ObjectEncryptor.encrypt(params)
    end

    @device = Device.new(:key => params[:udid])
    choose_experiment(:offer_instructions_test) unless @device.last_run_time_tester?

    complete_action_data = {
      :udid                  => params[:udid],
      :publisher_app_id      => params[:publisher_app_id],
      :currency              => @currency,
      :click_key             => params[:click_key],
      :device_click_ip       => params[:device_click_ip],
      :itunes_link_affiliate => params[:itunes_link_affiliate],
      :library_version       => params[:library_version],
      :os_version            => params[:os_version],
    }

    if @offer.pay_per_click?(:ppc_on_instruction)
      @complete_instruction_url = @offer.instruction_action_url(complete_action_data.merge(:viewed_at => Time.zone.now.to_f))
    else
      @complete_instruction_url = @offer.complete_action_url(complete_action_data)
    end

    render 'index_redesign' if choose_redesign?
  end

  def app_not_installed
    return unless verify_params([ :data, :id, :action_app_id ])
    @offer = Offer.find_in_cache(params[:id])
    @action_app = App.find_in_cache(params[:action_app_id])
    return unless verify_records([ @offer, @action_app ])
  end

  private

  def instructions_layout
    @show_topbar = library_version >= '9'
    if params[:action] == 'index' && choose_redesign?
      'instructions'
    else
      'iphone'
    end
  end

  def choose_redesign?
    @device.last_run_time_tester? || params[:exp] == 'offer_instructions_experiment'
  end

  def save_web_request
    WebRequest.log_offer_instructions(Time.zone.now, params, ip_address, geoip_data, request.headers['User-Agent'])
  end
end
