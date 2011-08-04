class VideosController < ApplicationController
  
  before_filter :setup
  
  def index
  end
 
private

  def setup
    params[:currency_id] ||= params[:app_id]
    return unless verify_params([ :app_id, :udid, :currency_id, :publisher_user_id])
    
    now = Time.zone.now
    geoip_data = get_geoip_data
    geoip_data[:country] = params[:country_code] if params[:country_code].present?
        
    device = Device.new(:key => params[:udid])
    publisher_app = App.find_in_cache(params[:app_id])
    currency = Currency.find_in_cache(params[:currency_id])
    currency = nil if currency.present? && currency.app_id != params[:app_id]
    return unless verify_records([ publisher_app, currency ], :render_missing_text => false)
    
    params[:publisher_app_id] = publisher_app.id
    
    web_request = WebRequest.new(:time => now)
    web_request.put_values('videos_requested', params, get_ip_address, geoip_data, request.headers['User-Agent'])

    offer_list, more_data_available = publisher_app.get_offer_list(
        :device             => device,
        :currency           => currency,
        :device_type        => params[:device_type],
        :geoip_data         => geoip_data,
        :required_length    => 100,
        :os_version         => params[:os_version],
        :type               => Offer::VIDEO_OFFER_TYPE,
        :library_version    => params[:library_version],
        :screen_layout_size => params[:screen_layout_size])
        
    if offer_list.any?
      weight_scale = 1 - offer_list.last.rank_score
      weights = offer_list.collect { |offer| offer.rank_score + weight_scale }
      @offer = offer_list.weighted_rand(weights)
    else
      @offer = nil
    end
  
    if @offer.present?
      @click_url = offer.get_click_url(
          :publisher_app     => publisher_app,
          :publisher_user_id => params[:publisher_user_id],
          :udid              => params[:udid],
          :currency_id       => currency.id,
          :source            => 'videos',
          :viewed_at         => now,
          :displayer_app_id  => params[:app_id],
          :country_code      => geoip_data[:country]
      )
      @amount = currency.get_visual_reward_amount(@offer, params[:display_multiplier])
    end
    
    web_request.save
  end 

end
