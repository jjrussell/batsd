class ValidateVideoController < ApplicationController
  
  before_filter :setup
  
  def index
    @valid = @offer.is_valid_for?(@publisher_app, @device, @currency, params[:device_type], @geoip_data, params[:app_version], @direct_pay_providers, @offer.item_type, @hide_app_offers, params[:library_version], params[:os_version], params[:screen_layout_size])
  end
  
private

  def setup
    params[:currency_id] ||= params[:app_id]
    return unless verify_params([ :app_id, :udid, :currency_id, :offer_id, :publisher_user_id ])
    
    now = Time.zone.now
    @geoip_data = get_geoip_data
    @geoip_data[:country] = params[:country_code] if params[:country_code].present?
    
    @device = Device.new(:key => params[:udid])
    @publisher_app = App.find_in_cache(params[:app_id])
    @currency = Currency.find_in_cache(params[:currency_id])
    @currency = nil if @currency.present? && @currency.app_id != params[:app_id]
    if params[:offer_id] == 'test_video'
      @offer = build_test_video_offer(@publisher_app).primary_offer
    else
      @offer = Offer.find_in_cache(params[:offer_id])
    end
    return unless verify_records([ @publisher_app, @currency, @offer ], :render_missing_text => false)
    
    @hide_app_offers = @currency.hide_rewarded_app_installs_for_version?(params[:app_version], params[:source])
    @direct_pay_providers = params[:direct_pay_providers].to_s.split(',')
    @amount = @currency.get_visual_reward_amount(@offer, params[:display_multiplier])
    
    @click_url = @offer.click_url(
        :publisher_app     => @publisher_app,
        :publisher_user_id => params[:publisher_user_id],
        :udid              => params[:udid],
        :currency_id       => @currency.id,
        :source            => 'videos',
        :viewed_at         => now,
        :displayer_app_id  => params[:app_id],
        :country_code      => @geoip_data[:country]
    )
  end
end
