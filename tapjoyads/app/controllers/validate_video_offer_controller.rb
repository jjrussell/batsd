class ValidateVideoOfferController < ApplicationController
  
  before_filter :set_device_type, :setup
  
  def index
    @valid = @offer.is_valid_for?(@publisher_app, @device, @currency, params[:device_type], @geoip_data, params[:app_version], @direct_pay_providers, params[:type], @hide_app_offers, params[:library_version], params[:os_version], params[:screen_layout_size])
  end
  
private

  def setup
    params[:currency_id] ||= params[:app_id]
    return unless verify_params([ :app_id, :udid, :currency_id, :offer_id, :type ])
    
    @geoip_data = get_geoip_data
    @geoip_data[:country] = params[:country_code] if params[:country_code].present?
    
    @device = Device.new(:key => params[:udid])
    @publisher_app = App.find_in_cache(params[:app_id])
    @currency = Currency.find_in_cache(params[:currency_id])
    @currency = nil if @currency.present? && @currency.app_id != params[:app_id]
    @offer = Offer.find_in_cache(params[:offer_id])    
    return unless verify_records([ @publisher_app, @currency, @offer ], :render_missing_text => false)
    
    @hide_app_offers = @currency.hide_rewarded_app_installs_for_version?(params[:app_version], params[:source])
    @direct_pay_providers = params[:direct_pay_providers].to_s.split(',')
    @amount = @currency.get_visual_reward_amount(@offer, params[:display_multiplier])
  end
  
  ##
  # Sets the device_type parameter from the device_ua param, which AdMarvel sends.
  def set_device_type
    if params[:device_type].blank? && params[:device_ua].present?
      params[:device_type] = case params[:device_ua]
      when /iphone;/i
        'iphone'
      when /ipod;/i
        'ipod'
      when /ipad;/i
        'ipad'
      when /android/i
        'android'
      when /windows/i
        'windows'
      else
        nil
      end
    end
  end
  
end
