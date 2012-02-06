class Apps::OffersController < WebsiteController
  layout 'apps'
  current_tab :apps

  filter_access_to :all
  before_filter :setup, :except => [ :toggle ]
  after_filter :save_activity_logs, :only => [ :create, :update, :toggle ]

  def new
    offer_params = {}
    if params[:offer_type] == 'rewarded_featured'
      offer_params = {:featured => true, :rewarded => true}
    elsif params[:offer_type] == 'non_rewarded_featured'
      offer_params = {:featured => true, :rewarded => false}
    elsif params[:offer_type] == 'non_rewarded'
      offer_params = {:featured => false, :rewarded => false}
    else
      offer_params = {:featured => false, :rewarded => true}
    end
    @offer = Offer.new(offer_params)
  end

  def create
    if params[:offer_type] == 'rewarded_featured'
      @offer = @app.primary_rewarded_featured_offer || @app.primary_offer.create_rewarded_featured_clone
    elsif params[:offer_type] == 'non_rewarded_featured'
      @offer = @app.primary_non_rewarded_featured_offer || @app.primary_offer.create_non_rewarded_featured_clone
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

    set_custom_creative_sizes
  end

  def preview
    @show_generated_ads = @offer.uploaded_icon?
    unless request.xhr?
      redirect_to edit_app_offer_path(:id => @offer.id, :app_id => @app.id, :show_preview => 'true', :preview_image_size => params[:image_size]) and return
    end
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
          :name, :name_suffix, :show_rate, :min_conversion_rate, :countries, :device_types,
          :publisher_app_whitelist, :overall_budget, :min_bid_override, :dma_codes, :regions ]
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
      set_custom_creative_sizes
      render :action => :edit
    end
  end

  def upload_creative
    @image_size = params[:image_size]
    @label = params[:label]
    email_managers = false
    image_data = params[:offer]["custom_creative_#{@image_size}".to_sym].read rescue nil

    modifying = true
    case request.method
      when :delete
        @offer.remove_banner_creative(@image_size)
      when :post
        @offer.add_banner_creative(@image_size)

        if permitted_to?(:edit, :statz)
          @offer.approve_banner_creative(@image_size)
        else
          @offer.add_banner_approval(current_user, @image_size)
          email_managers = true
        end
      when :put
        # do nothing
      when :get
        modifying = false
    end

    if modifying
      @offer.send("banner_creative_#{@image_size}_blob=", image_data)
      if @offer.save
        @success_message = "File #{request.method == :delete ? 'removed' : 'uploaded'} successfully."

        if email_managers
          approval_link = creative_tools_offers_url(:offer_id => @offer.id)
          emails = @offer.partner.account_managers.map(&:email)
          emails << 'support@tapjoy.com'
          emails.each do |mgr|
            TapjoyMailer.deliver_approve_offer_creative(mgr, @offer, @app, approval_link)
          end
        end
      else
        @error_message = @offer.errors["custom_creative_#{@image_size}_blob".to_sym]
        @offer.reload # we want the form to reset back to the way it was
      end
    end

    @creative_exists = @offer.has_banner_creative?(@image_size)
    @creative_approved = @offer.banner_creative_approved?(@image_size)
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

  def set_custom_creative_sizes
    if @offer.featured?
      @custom_creative_sizes = Offer::FEATURED_AD_SIZES.collect do |size|
        width, height = size.split("x").collect{|x|x.to_i}
        orientation = width > height ? "(landscape)" : "(portrait)"
        { :image_size         => size,
          :label_image_size   => "#{size} #{orientation}" }
      end
    elsif !@offer.rewarded?
      @custom_creative_sizes = Offer::DISPLAY_AD_SIZES.collect { |size| { :image_size => size, :label_image_size => "#{size} creative" }}
    end
  end
end
