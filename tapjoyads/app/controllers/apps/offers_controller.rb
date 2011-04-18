class Apps::OffersController < WebsiteController
  layout 'apps'
  current_tab :apps

  filter_access_to :all
  before_filter :find_offer
  after_filter :save_activity_logs, :only => [ :update, :toggle ]

  def show
    if @offer.item_type == "App" && !@offer.tapjoy_enabled?
      now = Time.zone.now
      start_time = now.beginning_of_hour - 23.hours
      end_time = now
      granularity = :hourly
      if @offer.integrated?
        flash.now[:notice] = "When you are ready to go live with this campaign, please click the button below to submit an enable app request."
      else
        url = @offer.item.is_android? ? ANDROID_CONNECT_SDK : IPHONE_CONNECT_SDK
        flash.now[:warning] = "Please note that you must integrate the <a href='#{url}'>Tapjoy advertiser library</a> before we can enable your campaign"
      end

      if @offer.enable_offer_requests.pending.present?
        @enable_request = @offer.enable_offer_requests.pending.first
      else
        @enable_request = @offer.enable_offer_requests.build
      end
    end

  end

  def update
    params[:offer].delete(:payment)
    params[:offer][:daily_budget].gsub!(',', '') if params[:offer][:daily_budget].present?
    params[:offer][:daily_budget] = 0 if params[:daily_budget] == 'off'
    offer_params = sanitize_currency_params(params[:offer], [ :bid, :min_bid_override ])

    safe_attributes = [:daily_budget, :user_enabled, :bid, :self_promote_only]
    if permitted_to?(:edit, :statz)
      offer_params[:device_types] = offer_params[:device_types].blank? ? '[]' : offer_params[:device_types].to_json
      safe_attributes += [:tapjoy_enabled, :allow_negative_balance, :pay_per_click,
          :featured, :name, :name_suffix, :show_rate, :min_conversion_rate, :countries,
          :cities, :postal_codes, :device_types, :publisher_app_whitelist, :overall_budget, :min_bid_override]
    end

    if @offer.safe_update_attributes(offer_params, safe_attributes)
      flash[:notice] = 'Pay-per-install was successfully updated'
    else
      flash[:error] = 'Update unsuccessful'
    end
    redirect_to(app_offer_path(:app_id => @app.id, :id => @offer.id))
  end

  def toggle
    @offer.user_enabled = params[:user_enabled]
    if @offer.save
      render :nothing => true
    else
      render :json => {:error => true}
    end
  end

  def percentile
    @offer.bid = sanitize_currency_param(params[:bid])
    @offer.update_payment
    estimate = @offer.estimated_percentile
    render :json => { :percentile => estimate, :ordinalized_percentile => estimate.ordinalize }
  rescue
    render :json => { :percentile => "N/A", :ordinalized_percentile => "N/A" }
  end

private
  def find_offer
    if permitted_to? :edit, :statz
      @app = App.find(params[:app_id], :include => [:primary_offer])
    else
      @app = current_partner.apps.find(params[:app_id], :include => [:primary_offer])
    end
    
    if params[:id]
      @offer = @app.offers.find(params[:id])
      if @offer.featured? && params[:action] == 'edit'
        redirect_to edit_app_featured_offer_path(@app, @offer) and return
      end
    else
      @offer = @app.primary_offer
    end
    log_activity(@offer)
  end
end
