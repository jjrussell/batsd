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
    raise "Only non-rewarded offers should be preview-able" if @offer.rewarded?
    
    bucket = S3.bucket(BucketNames::TAPJOY)
    key = RightAws::S3::Key.create(bucket, "icons/src/#{Offer.hashed_icon_id(@offer.icon_id)}.jpg")
    @show_generated_ads = key.exists?
    
    render :layout => 'simple'
  end
  
  def update
    params[:offer].delete(:payment)
    
    params[:offer][:banner_creatives] = "";
    Offer::DISPLAY_AD_SIZES.each do |size_key, size|
      param_name = "#{size}_custom_creative".to_sym
      creative_file = params[:offer][param_name]
      
      if !creative_file and @offer.has_banner_creative_for_size?(size) and params["remove_#{param_name}".to_sym] != "1"
        # nothing has changed, keep banner_creative as-is
        format_key = @offer.banner_creative_format_key_for_size(size)
        params[:offer][:banner_creatives] << "#{size_key},#{format_key};"
      end
      
      # TODO: delete "removed" creative files from S3? May want to write a job for that later. Meanwhile, taking up space unnecessarily isn't a big deal
      
      if creative_file # new file has been uploaded
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
          flash[:error] = "#{size} creative file is invalid - please provide one of the following file types: #{Offer::DISPLAY_AD_FORMATS.values.join(', ')} (.gifs must be static)"
          redirect_to :action => :edit and return
        end
        dimensions = "#{creative.columns}x#{creative.rows}"
        if dimensions != size
          flash[:error] = "#{size} creative file has invalid dimensions"
          redirect_to :action => :edit and return
        end
        begin
          bucket = S3.bucket(BucketNames::TAPJOY)
          creative_key = "#{@offer.id}_#{size}.#{format}"
          bucket.put("banner_creatives/#{creative_key}", creative.to_blob, {}, 'public-read')
        rescue
          flash[:error] = "Encountered unexpected error while uploading #{size} creative file, please try again"
          redirect_to :action => :edit and return
        end
        begin
          Mc.put("banner_creatives.#{creative_key}", creative.to_blob, false, 1.hour)
        rescue
        end
        format_key = Offer::DISPLAY_AD_FORMATS.invert[format]
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
