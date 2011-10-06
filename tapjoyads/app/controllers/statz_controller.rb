class StatzController < WebsiteController
  include ActionView::Helpers::NumberHelper
  
  layout 'tabbed'
  
  filter_access_to :all
  
  before_filter :find_offer, :only => [ :show, :edit, :update, :new, :create, :last_run_times, :udids, :download_udids ]
  before_filter :setup, :only => [ :show, :global ]
  before_filter :set_platform, :only => [ :global, :publisher, :advertiser ]
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
    
    if @offer.update_attributes(offer_params)
      flash[:notice] = "Successfully updated #{@offer.name}"
      redirect_to statz_path(@offer)
    else
      flash.now[:error] = "Errors encountered, please see messages below"
      render :action => :edit
    end
  end
  
  def new
  end
  
  def create
    new_offer = @offer.clone
    new_offer.update_attributes!(:created_at => nil, :updated_at => nil, :tapjoy_enabled => false, :name_suffix => params[:suffix])
    flash[:notice] = "Successfully created offer"
    redirect_to statz_path(new_offer)
  end
  
  def last_run_times
    targeted_devices = @offer.get_device_types
    targeted_platforms = []
    targeted_platforms << 'windows' if Offer::WINDOWS_DEVICES.any? { |device_type| targeted_devices.include?(device_type) }
    targeted_platforms << 'android' if Offer::ANDROID_DEVICES.any? { |device_type| targeted_devices.include?(device_type) }
    targeted_platforms << 'iphone'  if Offer::APPLE_DEVICES.any?   { |device_type| targeted_devices.include?(device_type) }

    admin_devices = AdminDevice.platform_in(targeted_platforms).ordered_by_description
    
    unless params[:other_udid].blank?
      admin_devices.unshift(AdminDevice.new(:udid => params[:other_udid], :description => 'Other UDID'))
    end
    
    @last_run_times = []
    admin_devices.each do |admin_device|
      device = Device.new(:key => admin_device.udid)
      last_run_time = device.has_app?(@offer.item_id) ? device.last_run_time(@offer.item_id).to_s(:pub_ampm_sec) : 'Never'
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
    load_partner_stats
  end

  def advertiser
    load_partner_stats
  end
  
  def gamez
    Time.zone = 'UTC'
    start_date = Time.zone.parse(params[:start_date].to_s)
    end_date = Time.zone.parse(params[:end_date].to_s)
    
    where_clause = "source = 'tj_games'"
    where_clause += " and created >= '#{start_date.to_i}'" if start_date.present?
    where_clause += " and created < '#{end_date.to_i}'" if end_date.present?
    
    data = "created,created_date,publisher_app_id,advertiser_app_id,udid,publisher_amount,advertiser_amount,tapjoy_amount,currency_reward,r.country\n"
    NUM_REWARD_DOMAINS.times do |i|
      Reward.select(:domain_name => "rewards_#{i}", :where => where_clause) do |r|
        data += "#{r.created.to_s},#{r.created.to_date.to_s},#{r.publisher_app_id},#{r.advertiser_app_id},#{r.udid},#{r.publisher_amount},#{r.advertiser_amount},#{r.tapjoy_amount},#{r.currency_reward},#{r.country}\n"
      end
    end
    
    send_data(data, :type => 'text/csv', :filename => "tj-games-conversions_#{Time.zone.now.to_s}.csv")
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
      options[:stat_prefix] = get_stat_prefix('global')
    else
      key = @offer.id
    end
    @appstats = Appstats.new(key, options)
  end

  def setup
    @start_time, @end_time, @granularity = Appstats.parse_dates(params[:date], params[:end_date], params[:granularity])
  end

  def load_partner_stats
    @timeframe = params[:timeframe] || '24_hours'
    prefix = get_stat_prefix('partner')
    @last_updated = Time.zone.at(Mc.get("statz.#{prefix}.last_updated.#{@timeframe}") || 0)
    @cached_stats = Mc.distributed_get("statz.#{prefix}.cached_stats.#{@timeframe}") || []
  end
end
