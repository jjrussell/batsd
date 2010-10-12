class StatzController < WebsiteController
  include ActionView::Helpers::NumberHelper
  
  layout 'tabbed'
  
  filter_access_to :all
  
  before_filter :find_offer, :only => [ :show, :edit, :update, :new, :create, :last_run_times, :udids, :download_udids ]
  after_filter :save_activity_logs, :only => [ :update ]
  
  def index
    @timeframe = params[:timeframe] || '24_hours'
    
    @money_stats = @timeframe == '1_month' ? Mc.get('money.daily_cached_stats') : Mc.get('money.cached_stats')
    
    @last_updated = Time.zone.at(Mc.get("statz.last_updated.#{@timeframe}") || 0)
    @cached_stats = Mc.get("statz.cached_stats.#{@timeframe}") || []
  end

  def udids
    bucket = S3.bucket(BucketNames::AD_UDIDS)
    base_path = Offer.s3_udids_path(@offer.id)
    @keys = bucket.keys('prefix' => base_path).map do |key|
      key.name.gsub(base_path, '')
    end
  end

  def download_udids
    return unless verify_params([ :date ], { :allow_empty => false }) && params[:date] =~ /^\d{4}-\d{2}$/
    
    bucket = S3.bucket(BucketNames::AD_UDIDS)
    data = bucket.get(Offer.s3_udids_path(@offer.id) + params[:date])
    
    send_data(data, :type => 'text/csv', :filename => "#{@offer.id}_#{params[:date]}.csv")
  end

  def show
    # setup the start/end times
    now = Time.zone.now
    @start_time = now.beginning_of_hour - 23.hours
    @end_time = now
    unless params[:date].blank?
      @start_time = Time.zone.parse(params[:date]).beginning_of_day
      @start_time = now.beginning_of_hour - 23.hours if @start_time > now
      @end_time = @start_time + 24.hours
    end
    unless params[:end_date].blank?
      @end_time = Time.zone.parse(params[:end_date]).end_of_day
      @end_time = now if @end_time <= @start_time || @end_time > now
    end
    
    # setup granularity
    if params[:granularity] == 'daily' || @end_time - @start_time >= 7.days
      @granularity = :daily
    else
      @granularity = :hourly
    end
    
    # lookup the stats
    appstats = Appstats.new(@offer.id, { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true })
    
    # setup the graph data
    intervals = appstats.intervals.map { |time| time.to_s(:pub_ampm) }
    
    @connect_data = {
      :name => 'Connects',
      :intervals => intervals,
      :xLabels => appstats.x_labels,
      :main => {
        :names => [ 'Connects', 'New Users' ],
        :data => [ appstats.stats['logins'], appstats.stats['new_users'] ],
        :totals => [ appstats.stats['logins'].sum, appstats.stats['new_users'].sum ]
      }
    }
    if @granularity == :daily
      @connect_data[:main][:names] << 'DAUs'
      @connect_data[:main][:data] << appstats.stats['daily_active_users']
      @connect_data[:main][:totals] << '-'
      @connect_data[:right] = {
        :unitPrefix => '$',
        :decimals => 2,
        :names => [ 'ARPDAU' ],
        :data => [ appstats.stats['arpdau'].map { |i| i / 100.0 } ],
        :stringData => [ appstats.stats['arpdau'].map { |i| number_to_currency(i / 100.0) } ],
        :totals => [ '-' ]
      }
    end
    
    @rewarded_installs_plus_spend_data = {
      :name => 'Rewarded installs + spend',
      :intervals => intervals,
      :xLabels => appstats.x_labels,
      :main => {
        :names => [ 'Paid installs', 'Paid clicks' ],
        :data => [ appstats.stats['paid_installs'], appstats.stats['paid_clicks'] ],
        :totals => [ appstats.stats['paid_installs'].sum, appstats.stats['paid_clicks'].sum ]
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Spend' ],
        :data => [ appstats.stats['installs_spend'].map { |i| i / -100.0 } ],
        :stringData => [ appstats.stats['installs_spend'].map { |i| number_to_currency(i / -100.0) } ],
        :totals => [ number_to_currency(appstats.stats['installs_spend'].sum / -100.0) ]
      },
      :extra => {
        :names => [ 'CVR' ],
        :data => [ appstats.stats['cvr'].map { |cvr| "%.0f%" % (cvr.to_f * 100.0) } ],
        :totals => [ appstats.stats['paid_clicks'].sum > 0 ? ("%.1f%" % (appstats.stats['paid_installs'].sum.to_f / appstats.stats['paid_clicks'].sum * 100.0)) : '-' ]
      }
    }
    
    @rewarded_installs_plus_rank_data = {
      :name => 'Rewarded installs + rank',
      :intervals => intervals,
      :xLabels => appstats.x_labels,
      :main => {
        :names => [ 'Paid installs', 'Paid clicks' ],
        :data => [ appstats.stats['paid_installs'], appstats.stats['paid_clicks'] ],
        :totals => [ appstats.stats['paid_installs'].sum, appstats.stats['paid_clicks'].sum ]
      },
      :right => {
        :yMax => 100,
        :names => [ 'Rank' ],
        :data => [ appstats.stats['overall_store_rank'].map { |r| r == '-' || r == '0' ? nil : r } ],
        :totals => [ (appstats.stats['overall_store_rank'].select { |r| r != '0' }.last || '-') ]
      }
    }
    
    @published_offers_data = {
      :name => 'Published offers',
      :intervals => intervals,
      :xLabels => appstats.x_labels,
      :main => {
        :names => [ 'Offers Completed', 'Offer clicks' ],
        :data => [ appstats.stats['rewards'], appstats.stats['rewards_opened'] ],
        :totals => [ appstats.stats['rewards'].sum, appstats.stats['rewards_opened'].sum ]
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Revenue' ],
        :data => [ appstats.stats['rewards_revenue'].map { |i| i / 100.0 } ],
        :stringData => [ appstats.stats['rewards_revenue'].map { |i| number_to_currency(i / 100.0) } ],
        :totals => [ number_to_currency(appstats.stats['rewards_revenue'].sum / 100.0) ]
      },
      :extra => {
        :names => [ 'CVR' ],
        :data => [ appstats.stats['rewards_cvr'].map { |cvr| "%.0f%" % (cvr.to_f * 100.0) } ],
        :totals => [ appstats.stats['rewards_opened'].sum > 0 ? ("%.1f%" % (appstats.stats['rewards'].sum.to_f / appstats.stats['rewards_opened'].sum * 100.0)) : '-' ]
      }
    }
    
    @offerwall_views_data = {
      :name => 'Offerwall views',
      :intervals => intervals,
      :xLabels => appstats.x_labels,
      :main => {
        :names => [ 'Offerwall views' ],
        :data => [ appstats.stats['offerwall_views'] ],
        :totals => [ appstats.stats['offerwall_views'].sum ]
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Offerwall eCPM' ],
        :data => [ appstats.stats['offerwall_ecpm'].map { |i| i / 100.0 } ],
        :stringData => [ appstats.stats['offerwall_ecpm'].map { |i| number_to_currency(i / 100.0) } ],
        :totals => [ appstats.stats['offerwall_views'].sum > 0 ? number_to_currency(appstats.stats['rewards_revenue'].sum.to_f / (appstats.stats['offerwall_views'].sum / 1000.0) / 100.0) : '$0.00' ]
      }
    }
    
    @display_ads_data = {
      :name => 'Display ads',
      :intervals => intervals,
      :xLabels => appstats.x_labels,
      :main => {
        :names => [ 'Ads requested', 'Ads shown', 'Clicks', 'Conversions' ],
        :data => [ appstats.stats['display_ads_requested'], appstats.stats['display_ads_shown'], appstats.stats['display_clicks'], appstats.stats['display_conversions'] ],
        :totals => [ appstats.stats['display_ads_requested'].sum, appstats.stats['display_ads_shown'].sum, appstats.stats['display_clicks'].sum, appstats.stats['display_conversions'].sum ]
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Revenue' ],
        :data => [ appstats.stats['display_revenue'].map { |i| i / 100.0 } ],
        :stringData => [ appstats.stats['display_revenue'].map { |i| number_to_currency(i / 100.0) } ],
        :totals => [ number_to_currency(appstats.stats['display_revenue'].sum / 100.0) ]
      },
      :extra => {
        :names => [ 'Fill rate', 'CTR', 'CVR' ],
        :data => [ appstats.stats['display_fill_rate'].map { |r| "%.0f%" % (r.to_f * 100.0) },
                   appstats.stats['display_ctr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
                   appstats.stats['display_cvr'].map { |r| "%.0f%" % (r.to_f * 100.0) } ],
        :totals => [ appstats.stats['display_ads_requested'].sum > 0 ? ("%.1f%" % (appstats.stats['display_ads_shown'].sum.to_f / appstats.stats['display_ads_requested'].sum * 100.0)) : '-',
                     appstats.stats['display_ads_shown'].sum > 0 ? ("%.1f%" % (appstats.stats['display_clicks'].sum.to_f / appstats.stats['display_ads_shown'].sum * 100.0)) : '-',
                     appstats.stats['display_clicks'].sum > 0 ? ("%.1f%" % (appstats.stats['display_conversions'].sum.to_f / appstats.stats['display_clicks'].sum * 100.0)) : '-' ]
      }
    }
    
    @ratings_data = {
      :name => 'Ratings',
      :intervals => intervals,
      :xLabels => appstats.x_labels,
      :main => {
        :names => [ 'Ratings' ],
        :data => [ appstats.stats['ratings'] ],
        :totals => [ appstats.stats['ratings'].sum ]
      }
    }
    
    @virtual_goods_data = {
      :name => 'Virtual Goods',
      :intervals => intervals,
      :xLabels => appstats.x_labels,
      :main => {
        :names => [ 'Virtual good purchases' ],
        :data => [ appstats.stats['vg_purchases'] ],
        :totals => [ appstats.stats['vg_purchases'].sum ]
      }
    }
    
    @ads_data = {
      :name => 'Ad impressions',
      :intervals => intervals,
      :xLabels => appstats.x_labels,
      :main => {
        :names => [ 'Ad impressions' ],
        :data => [ appstats.stats['hourly_impressions'] ],
        :totals => [ appstats.stats['hourly_impressions'].sum ]
      }
    }
    
    # lookup associated offers
    @associated_offers = @offer.find_associated_offers
  end
  
  def edit
  end
  
  def update
    log_activity(@offer)
    
    offer_params = sanitize_currency_params(params[:offer], [ :payment, :min_payment ])
    
    orig_payment = @offer.payment
    orig_budget = @offer.daily_budget
    offer_params[:device_types] = offer_params[:device_types].blank? ? '[]' : offer_params[:device_types].to_json
    if @offer.update_attributes(offer_params)
      
      unless params[:app_store_id].blank?
        app = @offer.item
        orig_store_id = app.store_id
        log_activity(app)
        app.update_attribute(:store_id, params[:app_store_id])
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
    @udids_to_check = [
      { :udid => 'c73e730913822be833766efffc7bb1cf239d855a', :last_run_time => 'Never', :device_label => 'Ben iPhone'       },
      { :udid => '9ac478517b48da604bdb9fc15a3e48139d59660d', :last_run_time => 'Never', :device_label => 'Christine iPhone' },
      { :udid => 'f3de44744a306beb47407b9a23cd97d9fe03339a', :last_run_time => 'Never', :device_label => 'Christine iPad'   },
      { :udid => 'c0a77ec9da51b722a60295d8cf5e35eee5634e1f', :last_run_time => 'Never', :device_label => 'Chris iPhone'     },
      { :udid => '5c46e034cd005e5f2b08501820ecb235b0f13f33', :last_run_time => 'Never', :device_label => 'Hwan-Joon iPhone' },
      { :udid => '05f900a2b588c4ed140689145ddb4684a1681f20', :last_run_time => 'Never', :device_label => 'Kai iPad'         },
      { :udid => 'c720dd0a5f937735c1a76bce72fcd90ada73ad7d', :last_run_time => 'Never', :device_label => 'Kai iTouch'       },
      { :udid => 'a00000155c5106',                           :last_run_time => 'Never', :device_label => 'Linda Droid'      },
      { :udid => '4b910938aceaa723e0c0313aa7fa9f9d838a595e', :last_run_time => 'Never', :device_label => 'Linda iPad'       },
      { :udid => '820a1b9df38f3024f9018464c05dfbad5708f81e', :last_run_time => 'Never', :device_label => 'Linda iPhone'     },
      { :udid => 'b4c86b4530a0ee889765a166d80492b46f7f3636', :last_run_time => 'Never', :device_label => 'Ryan iPhone'      },
      { :udid => 'f0910f7ab2a27a5d079dc9ed50d774fcab55f91d', :last_run_time => 'Never', :device_label => 'Ryan iPad'        },
      { :udid => 'a100000d9833c5',                           :last_run_time => 'Never', :device_label => 'Stephen Evo'      },
      { :udid => 'cb662f568a4016a5b2e0bd617e53f70480133290', :last_run_time => 'Never', :device_label => 'Stephen iPad'     },
      { :udid => '21e3f395b9bbaf56667782ea3fe1241656684e21', :last_run_time => 'Never', :device_label => 'Stephen iTouch'   },
    ]
    
    unless params[:other_udid].blank?
      @udids_to_check.unshift({ :udid => params[:other_udid], :last_run_time => 'Never', :device_label => 'Other UDID' })
    end
    
    app_id = @offer.is_primary? ? @offer.id : @offer.item.primary_offer.id
    
    @udids_to_check.each do |hash|
      list = DeviceAppList.new(:key => hash[:udid])
      if list.has_app(app_id)
        hash[:last_run_time] = list.last_run_time(app_id).in_time_zone('Pacific Time (US & Canada)').to_s(:pub_ampm_sec)
      end
    end
  end
  
  def search
    results = Offer.find(:all,
      :conditions => [ "name LIKE ?", "%#{params[:term]}%" ],
      :select => 'id, name, name_suffix, tapjoy_enabled, payment, hidden',
      :order => 'hidden ASC, name ASC',
      :limit => 10
    ).collect do |o|
      label_string = o.name_with_suffix
      label_string += " (active)" if o.tapjoy_enabled? && o.payment > 0
      label_string += " (hidden)" if o.hidden?
      { :label => label_string, :url => statz_path(o) }
    end
    
    render(:json => results.to_json)
  end
  
private
  
  def find_offer
    @offer = Offer.find_by_id(params[:id])
    if @offer.nil?
      flash[:error] = "Could not find an offer with ID: #{params[:id]}"
      redirect_to statz_index_path
    end
  end
  
end
