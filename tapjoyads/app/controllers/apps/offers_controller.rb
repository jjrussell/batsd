class Apps::OffersController < WebsiteController
  layout 'apps'
  current_tab :apps

  filter_access_to :all
  before_filter :setup, :except => [ :toggle, :banner_creative_image ]
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
  
  def banner_creative_image
    creative_key = "#{params[:offer_id]}_#{params[:size]}.#{params[:format]}"
    image_data = Mc.get_and_put("banner_creatives.#{creative_key}", false, 1.hour) do
      bucket = S3.bucket(BucketNames::TAPJOY)
      bucket.get("banner_creatives/#{creative_key}")
    end
    send_data image_data, :type => "image/#{params[:format]}", :disposition => 'inline'
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
  
  def update
    params[:offer].delete(:payment)
    
    params[:offer][:banner_creatives] = "";
    Offer::DISPLAY_AD_SIZES.each do |size_key, size|
      param_name = "#{size}_custom_creative".to_sym
      creative_file = params[:offer][param_name]
      
      if !creative_file
        if @offer.has_banner_creative_for_size?(size) && params["remove_#{size}_custom_creative".to_sym] != "1" # nothing has changed, keep banner_creatives as-is
          format_key = Offer::DISPLAY_AD_FORMATS.invert.fetch(@offer.banner_creatives[size])
          params[:offer][:banner_creatives] << "#{size_key},#{format_key};"
        end
        # TODO: delete "removed" creative file from S3? If so, may want to do so farther down in case error occurs
      end
      
      if creative_file # new file has been uploaded... keep as separate block in case "remove" was selected *and* file was uploaded
        begin
          creative_arr = Magick::Image.from_blob(creative_file.read)
          if creative_arr.size != 1
            raise "image probably contains multiple layers (e.g. animated .gif)"
          end
          creative = creative_arr[0]
          format = creative.format.downcase
          if !Offer::DISPLAY_AD_FORMATS.values.include? format
            raise "invalid format"
          end
        rescue
          flash[:error] = "#{size} creative file is invalid - please provide a .png, .jpeg, or static .gif"
          render :action => :edit and return
        end
        dimensions = "#{creative.columns}x#{creative.rows}"
        if dimensions != size
          flash[:error] = "#{size} creative file has invalid dimensions"
          render :action => :edit and return
        end
        begin
          bucket = S3.bucket(BucketNames::TAPJOY)
          creative_key = "#{@offer.id}_#{size}.#{format}"
          bucket.put("banner_creatives/#{creative_key}", creative.to_blob, {}, 'public-read')
        rescue
          flash[:error] = "Encountered unexpected error while uploading #{size} creative file, please try again"
          render :action => :edit and return
        end
        begin
          Mc.put("banner_creatives.#{creative_key}", creative.to_blob, false, 1.hour)
        rescue
        end
        format_key = Offer::DISPLAY_AD_FORMATS.invert.fetch(format)
        params[:offer][:banner_creatives] << "#{size_key},#{format_key};"
      end
      
      params[:offer].delete(param_name)
    end
    params[:offer][:banner_creatives].chomp!(";")
    
    params[:offer][:daily_budget].gsub!(',', '') if params[:offer][:daily_budget].present?
    params[:offer][:daily_budget] = 0 if params[:daily_budget] == 'off'
    offer_params = sanitize_currency_params(params[:offer], [ :bid, :min_bid_override ])
    
    safe_attributes = [:daily_budget, :user_enabled, :bid, :self_promote_only, :min_os_version, :screen_layout_sizes, :banner_creatives]
    if permitted_to? :edit, :statz
      safe_attributes += [ :tapjoy_enabled, :allow_negative_balance, :pay_per_click,
          :name, :name_suffix, :show_rate, :min_conversion_rate, :countries, :cities,
          :postal_codes, :device_types, :publisher_app_whitelist, :overall_budget, :min_bid_override ]
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
