class OffersController < WebsiteController
  layout 'tabbed'
  current_tab :apps

  filter_access_to :all
  before_filter :find_offer
  after_filter :save_activity_logs, :only => [ :update ]

  def show
    if @offer.item_type == "App" && !@offer.tapjoy_enabled?
      now = Time.zone.now
      start_time = now.beginning_of_hour - 23.hours
      end_time = now
      granularity = :hourly
      stats = Appstats.new(@offer.item.id, { :start_time => start_time, :end_time => end_time, :granularity => granularity, :stat_types => [ 'logins' ] }).stats
      if stats['logins'].sum > 0
        flash[:notice] = "When you are ready to go live with this campaign, please email <a href='support+enable@tapjoy.com'>support+enable@tapjoy.com</a>."
      else
        sdk_url = @offer.item.is_android? ? ANDROID_CONNECT_SDK : IPHONE_CONNECT_SDK
        flash[:warning] = "Please note that you must integrate the <a href='#{sdk_url}'>Tapjoy advertiser library</a> before we can enable your campaign"
      end
    end
  end

  def update
    params[:offer].delete(:payment)
    offer_params = sanitize_currency_params(params[:offer], [ :bid ])

    safe_attributes = [:daily_budget, :user_enabled, :bid]
    if permitted_to?(:edit, :statz)
      offer_params[:device_types] = offer_params[:device_types].blank? ? '[]' : offer_params[:device_types].to_json
      safe_attributes += [:tapjoy_enabled, :self_promote_only, :allow_negative_balance, :pay_per_click,
          :featured, :name, :name_suffix, :show_rate, :min_conversion_rate, :countries,
          :cities, :postal_codes, :device_types, :publisher_app_whitelist, :overall_budget]
    end

    if @offer.safe_update_attributes(offer_params, safe_attributes)
      flash[:notice] = 'Pay-per-install was successfully updated'
      redirect_to(app_offer_path(:app_id => @app.id, :id => @offer.id))
    else
      flash[:error] = 'Update unsuccessful'
      render :action => "show"
    end
  end

  def download_udids
    bucket = S3.bucket(BucketNames::AD_UDIDS)
    data = bucket.get(Offer.s3_udids_path(@offer.id) + params[:date])
    send_data(data, :type => 'text/csv', :filename => "#{@offer.id}_#{params[:date]}.csv")
  end

private
  def find_offer
    if permitted_to? :edit, :statz
      @app = App.find(params[:app_id], :include => [:primary_offer])
    else
      @app = current_partner.apps.find(params[:app_id], :include => [:primary_offer])
    end
    @offer = @app.primary_offer
    log_activity(@offer)
  end
end
