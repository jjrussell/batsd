class Apps::FeaturedOffersController < WebsiteController
  layout 'tabbed'
  current_tab :apps
  before_filter :setup
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :update ]
  
  def new
    redirect_to edit_app_featured_offer_path(@app, @app.primary_featured_offer) if @app.primary_featured_offer
  end
  
  def create
    @offer = @app.primary_featured_offer || @app.primary_offer.create_featured_clone
    redirect_to edit_app_featured_offer_path(@app, @offer)
  end
  
  def edit
    if @offer.enable_offer_requests.pending.present?
      @enable_request = @offer.enable_offer_requests.pending.first
    else
      @enable_request = @offer.enable_offer_requests.build
    end
  end
  
  def update
    params[:offer].delete(:payment)
    params[:offer][:daily_budget].gsub!(',', '') if params[:offer][:daily_budget].present?
    params[:offer][:daily_budget] = 0 if params[:daily_budget] == 'off'
    offer_params = sanitize_currency_params(params[:offer], [ :bid, :min_bid_override ])
    
    safe_attributes = [:daily_budget, :user_enabled, :bid]
    if permitted_to? :edit, :statz
      offer_params[:device_types] = offer_params[:device_types].blank? ? '[]' : offer_params[:device_types].to_json
      safe_attributes += [:tapjoy_enabled, :self_promote_only, :allow_negative_balance, :pay_per_click,
          :name, :name_suffix, :show_rate, :min_conversion_rate, :countries, :cities,
          :postal_codes, :device_types, :publisher_app_whitelist, :overall_budget, :min_bid_override]
    end

    if @offer.safe_update_attributes(offer_params, safe_attributes)
      flash[:notice] = 'Featured Offer was successfully updated.'
      redirect_to(edit_app_featured_offer_path(@app, @offer))
    else
      if @offer.enable_offer_requests.pending.present?
        @enable_request = @offer.enable_offer_requests.pending.first
      else
        @enable_request = @offer.enable_offer_requests.build
      end
      flash.now[:error] = 'Could not update Featured Offer.'
      render :action => :edit
    end
  end

private

  def setup
    if permitted_to? :edit, :statz
      @app = App.find(params[:app_id], :include => [:primary_featured_offer])
    else
      @app = current_partner.apps.find(params[:app_id], :include => [:primary_featured_offer])
    end
    
    if params[:id]
      @offer = @app.featured_offers.find(params[:id])
      log_activity(@offer)
    end
  end

end
