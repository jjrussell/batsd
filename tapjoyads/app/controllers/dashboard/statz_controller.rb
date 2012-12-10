class Dashboard::StatzController < Dashboard::DashboardController

  layout 'tabbed'
  current_tab :statz

  filter_access_to :all

  before_filter :find_offer, :only => [ :show, :edit, :update, :new, :create, :last_run_times, :last_run, :udids, :download_udids, :support_request_reward_ratio, :show_rate_reasons ]
  before_filter :setup, :only => [ :show, :global ]
  before_filter :set_platform, :only => [ :global, :publisher, :advertiser ]
  after_filter :save_activity_logs, :only => [ :update ]

  def index
    @timeframe = params[:timeframe] || '24_hours'
    @display   = params[:display]   || 'summary'

    prefix = @display == 'summary' ? 'top_' : ''
    @cached_metadata = Mc.distributed_get("statz.#{prefix}metadata.#{@timeframe}") || {}
    @cached_stats = Mc.distributed_get("statz.#{prefix}stats.#{@timeframe}") || []
    @money_stats = Mc.distributed_get("statz.money.#{@timeframe}") || { :total => {}, :iphone => {}, :android  => {}, :windows => {}, :tj_games => {} }
    @last_updated_start = Time.zone.at(Mc.get("statz.last_updated_start.#{@timeframe}") || 0)
    @last_updated_end = Time.zone.at(Mc.get("statz.last_updated_end.#{@timeframe}") || 0)
    @devices_count = Mc.get('statz.devices_count') || 0
  end

  def udids
    @keys = UdidReports.get_available_months(@offer.id)
  end

  def download_udids
    data = UdidReports.get_monthly_report(@offer.id, params[:date])
    send_data(data, :type => 'text/csv', :filename => "#{@offer.id}_#{params[:date]}.csv")
  end

  def show
    support_requests, rewards = @offer.cached_support_requests_rewards
    if support_requests && rewards
      @srr_ratio = support_request_ratio_text(support_requests, rewards)
    end
    app = App.find_by_id(@offer.app_id) if @offer.primary? && @offer.item_type == 'App'
    if app && app.platform == 'android' && app.app_metadatas.count > 1
      @store_options = {}
      app.app_metadatas.each do |meta|
        @store_options[meta.store.name] = meta.store.sdk_name
      end
    end

    respond_to do |format|
      format.html do
        @associated_offers = @offer.associated_offers.all
        @active_boosts = @offer.rank_boosts.active.not_optimized
        @total_boost = @active_boosts.map(&:amount).sum
        @optimized_boosts = @offer.rank_boosts.active.optimized
        @total_optimized_boosts = @optimized_boosts.map(&:amount).sum
      end

      format.json do
        load_appstats
        render :json => { :data => @appstats.graph_data(:offer => @offer, :admin => true) }.to_json
      end
    end
  end

  def support_request_reward_ratio
    rewards = @offer.num_clicks_rewarded
    support_requests = @offer.num_support_requests
    render :text => support_request_ratio_text(support_requests, rewards)
  end

  def show_rate_reasons
    render :text => get_show_rate_reasons.join('; ')
  end

  def update
    log_activity(@offer)

    params[:offer][:daily_budget].gsub!(',', '') if params[:offer][:daily_budget].present?
    if params[:daily_budget_toggle] == 'off'
      params[:offer][:daily_budget] = 0
      params[:offer][:daily_cap_type] = nil
    end
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
    new_offer = @offer.clone_and_save! do |new_offer|
      new_offer.tapjoy_enabled = false
      new_offer.name_suffix = params[:suffix]
    end
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

  def last_run
    @runs = AdminDeviceLastRun.for(:app_id => @offer.id, :udid => params[:udid])

    if params[:time] && time = Time.zone.parse(params[:time])
      @last_run = @runs.find { |run| run.time.change(:usec => 0) == time }
    else
      @last_run = @runs.first
    end
  end

  def global
    @store_options = all_android_store_options
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

  private

  def support_request_ratio_text(support_requests, rewards)
    ratio = '-'
    ratio = ("%.4f" % ( Float(support_requests) / rewards)) if rewards > 0
    "Support Requests: #{support_requests}, Clicks Rewarded: #{rewards} ( #{ratio} )"
  end

  def find_offer
    @offer = Offer.find_by_id(params[:id])
    if @offer.nil?
      flash[:error] = "Could not find an offer with ID: #{params[:id]}"
      redirect_to statz_index_path
    elsif @offer.app_offer?
      @app_metadata = @offer.app_metadata
    end
  end

  def load_appstats
    return @appstats if defined? @appstats
    options = { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true, :store_name => @store_name }
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
    @store_name = params[:store_name] if params[:store_name].present?
  end

  def load_partner_stats
    @timeframe = params[:timeframe] || '24_hours'
    prefix = get_stat_prefix('partner')
    @last_updated_start = Time.zone.at(Mc.get("statz.#{prefix}.last_updated_start.#{@timeframe}") || 0)
    @last_updated_end = Time.zone.at(Mc.get("statz.#{prefix}.last_updated_end.#{@timeframe}") || 0)
    @cached_stats = Mc.distributed_get("statz.#{prefix}.cached_stats.#{@timeframe}") || []
  end

  def get_show_rate_reasons
    reasons = []
    now = Time.zone.now
    end_of_day = Time.parse('00:00 CST', now + 18.hours).utc
    start_of_day = end_of_day - 1.day
    stat_types = %w(paid_installs)
    appstats = Appstats.new(@offer.id, :start_time => start_of_day, :end_time => end_of_day, :stat_types => stat_types)
    num_installs_today = appstats.stats['paid_installs'].sum

    if @offer.over_daily_budget?(num_installs_today)
      reasons << 'Pushed too many installs. Overriding any calculations and setting show rate to 0.'
    end

    if @offer.has_overall_budget?
      start_time = Time.zone.parse('2010-01-01')
      stat_types = %w(paid_installs)
      appstats_overall = Appstats.new(@offer.id, :start_time => start_time, :end_time => now, :stat_types => stat_types)
      total_installs = appstats_overall.stats['paid_installs'].sum
      reasons << 'App over overall_budget. Overriding any calculations and setting show rate to 0.' if total_installs > @offer.overall_budget
    end

    reasons
  end
end
