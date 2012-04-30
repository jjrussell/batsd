class FullscreenAdController < ApplicationController

  layout 'iphone'

  prepend_before_filter :decrypt_data_param

  def index
    @platform = Device.device_type_to_platform(device_type)
    @publisher_app = App.find_in_cache(params[:publisher_app_id])
    currency_id = params[:currency_id].blank? ? params[:publisher_app_id] : params[:currency_id]
    @currency = Currency.find_in_cache(currency_id)
    @offer = Offer.find_in_cache(params[:offer_id])
    required_records = [ @publisher_app, @currency, @offer ]
    if params[:displayer_app_id].present?
      @displayer = App.find_in_cache(params[:displayer_app_id])
      required_records << @displayer
    end
    return unless verify_records(required_records)

    @now = params[:viewed_at].present? ? Time.zone.at(params[:viewed_at].to_f) : Time.zone.now

    render :layout => "blank" if @offer.featured_custom_creative?
  end

  def test_offer
    @publisher_app = App.find_in_cache(params[:publisher_app_id])
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    required_records = [ @publisher_app, @currency ]
    if params[:displayer_app_id].present?
      @displayer = App.find_in_cache(params[:displayer_app_id])
      required_records << @displayer
    end
    return unless verify_records(required_records)

    @offer = @publisher_app.test_offer
    @now = params[:viewed_at].present? ? Time.zone.at(params[:viewed_at].to_f) : Time.zone.now
    render :action => :index
  end

  def test_video_offer
    @publisher_app = App.find_in_cache(params[:publisher_app_id])
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    required_records = [ @publisher_app, @currency ]
    if params[:displayer_app_id].present?
      @displayer = App.find_in_cache(params[:displayer_app_id])
      required_records << @displayer
    end
    return unless verify_records(required_records)

    @offer = @publisher_app.test_video_offer.primary_offer
    @now = params[:viewed_at].present? ? Time.zone.at(params[:viewed_at].to_f) : Time.zone.now
    render :action => :index
  end

  def skip
      device = Device.new(:key => params[:udid])
      device.add_skip(params[:offer_id])
      device.save
      render :nothing => true
  end
end
