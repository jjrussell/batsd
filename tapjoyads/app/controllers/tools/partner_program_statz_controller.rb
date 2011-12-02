class Tools::PartnerProgramStatzController < WebsiteController
  include ActionView::Helpers::NumberHelper

  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :find_offer, :only => [ :show, :edit, :update, :new, :create, :last_run_times, :udids, :download_udids ]
  before_filter :setup, :only => [ :index, :show, :global ]
  before_filter :set_platform, :only => [ :global, :publisher, :advertiser ]
  after_filter :save_activity_logs, :only => [ :update ]

  def index
    @timeframe = params[:timeframe] || '24_hours'
    @display   = params[:display]   || 'summary'

    #@money_stats = Mc.get('money.cached_stats') || { @timeframe => {} }
    #@money_last_updated = Time.zone.at(Mc.get("money.last_updated") || 0)

    prefix = @display == 'summary' ? 'top_' : ''
    @partner_program_metadata, @partner_program_stats, @partner_revenue_stats, @partner_names = get_stats(@start_time, @end_time) || {}
    #@last_updated_start = Time.zone.at(Mc.get("statz.last_updated_start.#{@timeframe}") || 0)
    #@last_updated_end = Time.zone.at(Mc.get("statz.last_updated_end.#{@timeframe}") || 0)
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
      @offer.find_associated_offers.each do |o|
        o.tapjoy_sponsored = offer_params[:tapjoy_sponsored]
        o.save! if o.changed?
      end
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
    @last_updated_start = Time.zone.at(Mc.get("statz.#{prefix}.last_updated_start.#{@timeframe}") || 0)
    @last_updated_end = Time.zone.at(Mc.get("statz.#{prefix}.last_updated_end.#{@timeframe}") || 0)
    @cached_stats = Mc.distributed_get("statz.#{prefix}.cached_stats.#{@timeframe}") || []
  end


  def get_stats(start_time, end_time)
    #start_time, end_time = get_times_for_vertica(timeframe)
    time_conditions      = "time >= '#{start_time.to_s(:db)}' AND time < '#{end_time.to_s(:db)}'"

    partner_program_offer_ids = Offer.tapjoy_sponsored_offer_ids.map { |o| "'#{o.id}'" }.join(',')  #is it necessary to add Offer.enabled_offers.tapjoy_sponsored_offer_ids here?

    partner_program_stats = {}
    VerticaCluster.query('analytics.actions', {
        :select     => 'offer_id, count(*) AS conversions',
        :group      => 'offer_id',
        :conditions => "path LIKE '%reward%' AND #{time_conditions} AND offer_id IN (#{partner_program_offer_ids})" }).each do |result|
        #:conditions => "path LIKE '%reward%' AND offer_id IN (#{partner_program_offer_ids})" }).each do |result|
      partner_program_stats[result[:offer_id]] = {
        'conversions'      => number_with_delimiter(result[:conversions]),
        'published_offers' => '0',
        'offers_revenue'   => 0, #put int 0 here for it's easier to calculate partner revenues below
      }
    end
    VerticaCluster.query('analytics.actions', {
        :select     => 'publisher_app_id AS offer_id, count(*) AS published_offers, sum(publisher_amount) AS offers_revenue',
        :group      => 'publisher_app_id',
        :conditions => "path LIKE '%reward%' AND #{time_conditions} AND publisher_app_id IN (#{partner_program_offer_ids})" }).each do |result|
        #:conditions => "path LIKE '%reward%' AND publisher_app_id IN (#{partner_program_offer_ids})" }).each do |result|
      partner_program_stats[result[:offer_id]] ||= { 'conversions' => '0' }
      partner_program_stats[result[:offer_id]]['published_offers'] = number_with_delimiter(result[:published_offers])
      partner_program_stats[result[:offer_id]]['offers_revenue']   = result[:offers_revenue] #won't call number_to_currency here for it's easier to calculate partner revenues below
    end
    
    partner_revenue_stats = {}
    partner_names = {}
    partner_program_metadata = {}
    Offer.find_each(:conditions => [ 'id IN (?)', partner_program_stats.keys ], :include => :partner) do |offer|
      partner_program_metadata[offer.id] = {
        'icon_url'           => offer.get_icon_url,
        'offer_name'         => offer.name_with_suffix,
        'price'              => number_to_currency(offer.price / 100.0),
        'payment'            => number_to_currency(offer.payment / 100.0),
        'balance'            => number_to_currency(offer.partner.balance / 100.0),
        'conversion_rate'    => number_to_percentage((offer.conversion_rate || 0) * 100.0, :precision => 1),
        'platform'           => offer.get_platform,
        'featured'           => offer.featured?,
        'rewarded'           => offer.rewarded?,
        'offer_type'         => offer.item_type,
        'overall_store_rank' => combined_ranks[offer.third_party_data] || '-',
        'sales_rep'          => offer.partner.sales_rep.to_s,
        'partner_pending_earnings'  => number_to_currency(offer.partner.pending_earnings / 100.0),
        'partner_id'         => offer.partner.id
      }
      partner_names[offer.partner.id] ||= offer.partner.name
      partner_revenue_stats[offer.partner.id] ||= 0
      partner_revenue_stats[offer.partner.id] += partner_program_stats[offer.id]['offers_revenue']
    end

    partner_program_stats_adv = partner_program_stats.sort do |s1, s2|
      s2[1]['conversions'].gsub(',', '').to_i <=> s1[1]['conversions'].gsub(',', '').to_i
    end

    return partner_program_metadata, partner_program_stats_adv, partner_revenue_stats, partner_names
  end

  def get_times_for_vertica(timeframe)
    most_recent = VerticaCluster.query('analytics.actions', :select => 'max(time)').first[:max]

    if timeframe == '24_hours'
      end_time   = most_recent - (most_recent.to_i % 10.minutes).seconds
      start_time = end_time - 24.hours
    elsif timeframe == '7_days'
      end_time   = most_recent.beginning_of_day
      start_time = end_time - 7.days
    elsif timeframe == '1_month'
      end_time   = most_recent.beginning_of_day
      start_time = end_time - 30.days
    end

    [ start_time, end_time ]
  end

  def combined_ranks
    @combined_ranks ||= begin
      ios_ranks_free     = Mc.get('store_ranks.ios.overall.free.united_states') || {}
      ios_ranks_paid     = Mc.get('store_ranks.ios.overall.paid.united_states') || {}
      android_ranks_free = Mc.get('store_ranks.android.overall.free.english')   || {}
      android_ranks_paid = Mc.get('store_ranks.android.overall.paid.english')   || {}

      ios_ranks_free.merge(ios_ranks_paid).merge(android_ranks_free).merge(android_ranks_paid)
    end
  end

end
