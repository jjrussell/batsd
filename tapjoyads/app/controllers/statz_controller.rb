class StatzController < WebsiteController
  include ActionView::Helpers::NumberHelper
  
  layout 'tabbed'
  
  filter_access_to :all
  
  before_filter :find_offer, :only => [ :show, :edit, :update, :new, :create, :last_run_times, :udids, :download_udids ]
  before_filter :setup, :only => [ :show, :global ]
  after_filter :save_activity_logs, :only => [ :update ]
  
  def index
    @timeframe = params[:timeframe] || '24_hours'
    
    @money_stats = Mc.get('money.cached_stats') || { @timeframe => {} }
    @money_last_updated = Time.zone.at(Mc.get("money.last_updated") || 0)
    
    @last_updated = Time.zone.at(Mc.get("statz.last_updated.#{@timeframe}") || 0)
    @cached_stats = Mc.distributed_get("statz.cached_stats.#{@timeframe}") || []
  end

  def udids
    @keys = UdidReports.get_available_months(@offer.id)
  end

  def download_udids
    data = UdidReports.get_monthly_report(@offer.id, params[:date])
    send_data(data, :type => 'text/csv', :filename => "#{@offer.id}_#{params[:date]}.csv")
  end

  def show
    respond_to do |format|
      format.html do
        @associated_offers = @offer.find_associated_offers
        @active_boosts = @offer.rank_boosts.active
        @total_boost = @active_boosts.map(&:amount).sum
      end

      format.json do
        load_appstats
        render :json => { :data => @appstats.graph_data(:offer => @offer, :admin => true) }.to_json
      end
    end
  end

  def update
    log_activity(@offer)
    offer_params = sanitize_currency_params(params[:offer], [ :bid, :min_bid_override ])
    offer_params[:device_types] = offer_params[:device_types].blank? ? '[]' : offer_params[:device_types].to_json
    if @offer.update_attributes(offer_params)
      
      unless params[:app_store_id].blank?
        app = @offer.item
        log_activity(app)
        app.update_attributes({ :store_id => params[:app_store_id] })
      end
      
      flash[:notice] = "Successfully updated #{@offer.name}"
      redirect_to statz_path(@offer)
    else
      render :action => :edit
    end
  end
  
  def new
  end
  
  def create
    new_offer = @offer.clone
    new_offer.tapjoy_enabled = false
    new_offer.name_suffix = params[:suffix]
    new_offer.save!
    flash[:notice] = "Successfully created offer"
    redirect_to statz_path(new_offer)
  end
  
  def last_run_times
    targeted_devices = @offer.get_device_types
    targeted_platforms = []
    targeted_platforms << 'android' if Offer::ANDROID_DEVICES.any? { |device_type| targeted_devices.include?(device_type) }
    targeted_platforms << 'iphone'  if Offer::APPLE_DEVICES.any?   { |device_type| targeted_devices.include?(device_type) }

    admin_devices = AdminDevice.platform_in(targeted_platforms).ordered_by_description
    
    unless params[:other_udid].blank?
      admin_devices.unshift(AdminDevice.new(:udid => params[:other_udid], :description => 'Other UDID'))
    end
    
    @last_run_times = []
    admin_devices.each do |admin_device|
      device = Device.new(:key => admin_device.udid)
      last_run_time = device.has_app(@offer.item_id) ? device.last_run_time(@offer.item_id).to_s(:pub_ampm_sec) : 'Never'
      @last_run_times << [ admin_device, last_run_time ]
    end
  end

  def global
    respond_to do |format|
      format.html do
      end
      format.json do
        load_appstats
        render :json => { :data => @appstats.graph_data(:admin => true) }.to_json
      end
    end
  end

  def publisher
    @timeframe = params[:timeframe] || '24_hours'
    @last_updated = Time.zone.at(Mc.get("statz.partners.last_updated.#{@timeframe}") || 0)
    @cached_stats = Mc.distributed_get("statz.partners.cached_stats.#{@timeframe}") || []
  end

  def advertiser
    @timeframe = params[:timeframe] || '24_hours'
    @last_updated = Time.zone.at(Mc.get("statz.partners.last_updated.#{@timeframe}") || 0)
    @cached_stats = Mc.distributed_get("statz.partners.cached_stats.#{@timeframe}") || []
  end
  
private
  
  def find_offer
    @offer = Offer.find_by_id(params[:id])
    if @offer.nil?
      flash[:error] = "Could not find an offer with ID: #{params[:id]}"
      redirect_to statz_index_path
    end
  end

  def load_appstats
    return @appstats if defined? @appstats
    options = { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true }
    if params[:action] == 'global'
      key = nil
      options[:cache_hours] = 0
      options[:stat_prefix] = 'global'
    else
      key = @offer.id
    end
    @appstats = Appstats.new(key, options)
  end

  def setup
    @start_time, @end_time, @granularity = Appstats.parse_dates(params[:date], params[:end_date], params[:granularity])
  end
end
