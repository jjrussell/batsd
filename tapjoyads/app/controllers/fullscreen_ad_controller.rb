class FullscreenAdController < ApplicationController

  layout 'iphone'

  def image
    offer = Offer.find_in_cache(params[:offer_id])
    if params[:image_size].present?
      width, height = params[:image_size].split("x")
    else
      # Default to showing low-res ad with portrait orientation
      width = 320
      height = 480
    end

    # Ensure that wkhtmltoimage waits until the Javascript has finished executing before generating the page.
    img = IMGKit.new(offer.fullscreen_ad_url(:publisher_app_id => params[:publisher_app_id], :width => width, :height => height),
                     :width => width, :height => height, :javascript_delay => 2000)

    prevent_browser_cache(params[:prevent_browser_cache])

    send_data img.to_png, :type => 'image/png', :disposition => 'inline'
  end

  def index
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
    @geoip_data = { :country => params[:country_code] }

    creative_exists = true if @offer.banner_creatives.any? { |size| Offer::FEATURED_AD_SIZES.include?(size) }
    render :custom_creative, :layout => "blank" if creative_exists
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

    @offer = build_test_offer(@publisher_app)
    @now = params[:viewed_at].present? ? Time.zone.at(params[:viewed_at].to_f) : Time.zone.now
    @geoip_data = { :country => params[:country_code] }
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

    @offer = build_test_video_offer(@publisher_app).primary_offer
    @now = params[:viewed_at].present? ? Time.zone.at(params[:viewed_at].to_f) : Time.zone.now
    @geoip_data = { :country => params[:country_code] }
    render :action => :index
  end
end
