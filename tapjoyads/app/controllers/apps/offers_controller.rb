class Apps::OffersController < WebsiteController
  layout 'apps'
  current_tab :apps

  filter_access_to :all
  before_filter :setup, :except => [ :toggle ]
  after_filter :save_activity_logs, :only => [ :create, :update, :toggle ]

  def new
  end

  def create
    if params[:offer_type] == 'featured'
      @offer = @app.primary_featured_offer || @app.primary_offer.create_featured_clone
    elsif params[:offer_type] == 'non_rewarded'
      @offer = @app.primary_non_rewarded_offer || @app.primary_offer.create_non_rewarded_clone
    end
    redirect_to :action => :edit, :id => @offer.id
  end

  def edit
    if !@offer.tapjoy_enabled?
      if @offer.rewarded? && !@offer.featured?
        if @offer.integrated?
          flash.now[:notice] = "When you are ready to go live with this campaign, please click the button below to submit an enable app request."
        else
          flash.now[:warning] = "Please note that you must integrate the <a href='#{@offer.item.sdk_url(:connect)}'>Tapjoy advertiser library</a> before we can enable your campaign"
        end
      end

      if @offer.enable_offer_requests.pending.present?
        @enable_request = @offer.enable_offer_requests.pending.first
      else
        @enable_request = @offer.enable_offer_requests.build
      end
    end
  end

  def preview
    @show_generated_ads = @offer.uploaded_icon?
    render 'apps/offers_shared/preview', :layout => false
  end

  def update
    params[:offer].delete(:payment)

    params[:offer][:daily_budget].gsub!(',', '') if params[:offer][:daily_budget].present?
    params[:offer][:daily_budget] = 0 if params[:daily_budget] == 'off'
    offer_params = sanitize_currency_params(params[:offer], [ :bid, :min_bid_override ])

    safe_attributes = [:daily_budget, :user_enabled, :bid, :self_promote_only, :min_os_version, :screen_layout_sizes]
    if permitted_to? :edit, :statz
      safe_attributes += [ :tapjoy_enabled, :allow_negative_balance, :pay_per_click,
          :name, :name_suffix, :show_rate, :min_conversion_rate, :countries,
          :device_types, :publisher_app_whitelist, :overall_budget, :min_bid_override, :dma_codes, :regions ]
    end

    if @offer.safe_update_attributes(offer_params, safe_attributes)
      flash[:notice] = 'Your offer was successfully updated.'
      redirect_to :action => :edit
    else
      if @offer.enable_offer_requests.pending.present?
        @enable_request = @offer.enable_offer_requests.pending.first
      else
        @enable_request = @offer.enable_offer_requests.build
      end
      flash.now[:error] = 'Your offer could not be updated.'
      render :action => :edit
    end
  end

  def upload_creative
    @size = params[:size]
    image_data = params[:offer]["custom_creative_#{@size}".to_sym].read rescue nil

    modifying = true
    case request.method
      when :delete
        # necessary to use assignment so @offer.banner_creatives_changed? will be true (can't modify in-place)
        @offer.banner_creatives -= @size.to_a
      when :post
        # necessary to use assignment so @offer.banner_creatives_changed? will be true (can't modify in-place)
        @offer.banner_creatives += @size.to_a
      when :put
        # do nothing
      when :get
        modifying = false
    end

    if modifying
      @offer.send("banner_creative_#{@size}_blob=", image_data)
      if @offer.save
        @success_message = "File #{request.method == :delete ? 'removed' : 'uploaded'} successfully"
      else
        @error_message = @offer.errors["custom_creative_#{@size}_blob".to_sym]
        @offer.reload # we want the form to reset back to the way it was
      end
    end

    @creative_exists = @offer.banner_creatives.include? @size
    render :layout => 'simple'
  end

  def toggle
    @offer = current_partner.offers.find(params[:id])
    log_activity(@offer)

    @offer.user_enabled = params[:user_enabled]
    if @offer.save
      render :nothing => true
    else
      render :json => {:error => true}
    end
  end

  def percentile
    @offer.bid = sanitize_currency_param(params[:bid])
    estimate = @offer.percentile
    render :json => { :percentile => estimate, :ordinalized_percentile => estimate.ordinalize }
  rescue
    render :json => { :percentile => "N/A", :ordinalized_percentile => "N/A" }
  end

  private

  def setup
    if permitted_to? :edit, :statz
      @app = App.find(params[:app_id])
    else
      @app = current_partner.apps.find(params[:app_id])
    end

    if params[:id]
      @offer = @app.offers.find(params[:id])
    else
      @offer = @app.primary_offer
    end
    log_activity(@offer)
  end
end
