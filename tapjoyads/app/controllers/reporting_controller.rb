class ReportingController < WebsiteController
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  
  layout 'tabbed'
  
  filter_access_to :all
  before_filter :find_offer, :only => [ :show, :export, :download_udids ]
  before_filter :setup, :only => [ :show, :export ]
  
  def index
    unless current_partner_offers.empty?
      if session[:last_shown_app].present?
        app = current_partner.apps.find_by_id(session[:last_shown_app])
        redirect_to reporting_path(app.primary_offer) and return unless app.nil?
      end
      redirect_to reporting_path(current_partner_offers.first)
    end
  end

  def show
    session[:last_shown_app] = @offer.item_id if @offer.item_type == 'App'

    if @granularity == :daily
      intervals = @appstats.intervals.map { |time| time.to_s(:pub) + " UTC"  }
    else
      intervals = @appstats.intervals.map { |time| time.to_s(:pub_ampm) }
    end
    
    conversion_name = @offer.item_type == 'App' ? 'installs' : 'conversions'

    respond_to do |format|
      format.html do
        bucket = S3.bucket(BucketNames::AD_UDIDS)
        base_path = Offer.s3_udids_path(@offer.id)
        @udids = bucket.keys('prefix' => base_path).map do |key|
          key.name.gsub(base_path, '')
        end
      end
      format.json do
        @data = {
          :connect_data => {
            :name => 'Sessions',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Sessions', 'New Users' ],
              :data => [ @appstats.stats['logins'], @appstats.stats['new_users'] ],
              :totals => [ @appstats.stats['logins'].sum, @appstats.stats['new_users'].sum ]
            }
          },

          :rewarded_installs_plus_spend_data => {
            :name => "Paid #{conversion_name} + Advertising spend",
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ "Paid #{conversion_name}", 'Paid clicks' ],
              :data => [ @appstats.stats['paid_installs'], @appstats.stats['paid_clicks'] ],
              :totals => [ @appstats.stats['paid_installs'].sum, @appstats.stats['paid_clicks'].sum ]
            },
            :right => {
              :unitPrefix => '$',
              :names => [ 'Advertising Spend' ],
              :data => [ @appstats.stats['installs_spend'].map { |i| i / -100.0 } ],
              :stringData => [ @appstats.stats['installs_spend'].map { |i| number_to_currency(i / -100.0) } ],
              :totals => [ number_to_currency(@appstats.stats['installs_spend'].sum / -100.0) ]
            },
            :extra => {
              :names => [ 'Conversion rate' ],
              :data => [ @appstats.stats['cvr'].map { |cvr| "%.0f%" % (cvr.to_f * 100.0) } ],
              :totals => [ @appstats.stats['paid_clicks'].sum > 0 ? ("%.1f%" % (@appstats.stats['paid_installs'].sum.to_f / @appstats.stats['paid_clicks'].sum * 100.0)) : '-' ]
            }
          },

          :rewarded_installs_plus_rank_data => {
            :name => "Paid #{conversion_name} + Ranks",
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ "Paid #{conversion_name}" ],
              :data => [ @appstats.stats['paid_installs'] ],
              :totals => [ @appstats.stats['paid_installs'].sum ]
            },
            :partition_names => get_rank_partition_names,
            :partition_values => get_rank_partition_values,
            :partition_title => 'Country',
            :partition_fallback => 'This app is not in the top charts in any categories for the selected date range.',
            :partition_default => 'United States'
          },

          :revenue_data => {
            :name => 'Revenue',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :unitPrefix => '$',
              :names => [ 'Total revenue', 'Offerwall revenue', 'Featured offer revenue', 'Display ad revenue' ],
              :data => [ @appstats.stats['total_revenue'].map { |i| i / 100.0 },
                         @appstats.stats['rewards_revenue'].map { |i| i / 100.0 },
                         @appstats.stats['featured_revenue'].map { |i| i / 100.0 },
                         @appstats.stats['display_revenue'].map { |i| i / 100.0 } ],
              :stringData => [ @appstats.stats['total_revenue'].map { |i| number_to_currency(i / 100.0) },
                               @appstats.stats['rewards_revenue'].map { |i| number_to_currency(i / 100.0) },
                               @appstats.stats['featured_revenue'].map { |i| number_to_currency(i / 100.0) },
                               @appstats.stats['display_revenue'].map { |i| number_to_currency(i / 100.0) } ],
              :totals => [ number_to_currency(@appstats.stats['total_revenue'].sum / 100.0),
                           number_to_currency(@appstats.stats['rewards_revenue'].sum / 100.0),
                           number_to_currency(@appstats.stats['featured_revenue'].sum / 100.0),
                           number_to_currency(@appstats.stats['display_revenue'].sum / 100.0) ]
            }
          },

          :offerwall_data => {
            :name => 'Offerwall',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Offerwall views', 'Clicks', 'Conversions' ],
              :data => [ @appstats.stats['offerwall_views'], @appstats.stats['rewards_opened'], @appstats.stats['rewards'] ],
              :totals => [ @appstats.stats['offerwall_views'].sum, @appstats.stats['rewards_opened'].sum, @appstats.stats['rewards'].sum ]
            },
            :right => {
              :unitPrefix => '$',
              :names => [ 'Revenue', 'eCPM' ],
              :data => [ @appstats.stats['rewards_revenue'].map { |i| i / 100.0 },
                         @appstats.stats['offerwall_ecpm'].map { |i| i / 100.0 } ],
              :stringData => [ @appstats.stats['rewards_revenue'].map { |i| number_to_currency(i / 100.0) },
                               @appstats.stats['offerwall_ecpm'].map { |i| number_to_currency(i / 100.0) } ],
              :totals => [ number_to_currency(@appstats.stats['rewards_revenue'].sum / 100.0), 
                           @appstats.stats['offerwall_views'].sum > 0 ? number_to_currency(@appstats.stats['rewards_revenue'].sum.to_f / (@appstats.stats['offerwall_views'].sum / 1000.0) / 100.0) : '$0.00' ]
            },
            :extra => {
              :names => [ 'CTR', 'CVR' ],
              :data => [ @appstats.stats['rewards_ctr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
                         @appstats.stats['rewards_cvr'].map { |r| "%.0f%" % (r.to_f * 100.0) } ],
              :totals => [ @appstats.stats['offerwall_views'].sum > 0 ? ("%.1f%" % (@appstats.stats['rewards_opened'].sum.to_f / @appstats.stats['offerwall_views'].sum * 100.0)) : '-',
                           @appstats.stats['rewards_opened'].sum > 0 ? ("%.1f%" % (@appstats.stats['rewards'].sum.to_f / @appstats.stats['rewards_opened'].sum * 100.0)) : '-' ]
            }
          },

          :featured_offers_data => {
            :name => 'Featured offers',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Offers requested', 'Offers shown', 'Clicks', 'Conversions' ],
              :data => [ @appstats.stats['featured_offers_requested'],
                         @appstats.stats['featured_offers_shown'],
                         @appstats.stats['featured_offers_opened'],
                         @appstats.stats['featured_published_offers'] ],
              :totals => [ @appstats.stats['featured_offers_requested'].sum,
                           @appstats.stats['featured_offers_shown'].sum,
                           @appstats.stats['featured_offers_opened'].sum,
                           @appstats.stats['featured_published_offers'].sum ]
            },
            :right => {
              :unitPrefix => '$',
              :names => [ 'Revenue', 'eCPM' ],
              :data => [ @appstats.stats['featured_revenue'].map { |i| i / 100.0 },
                         @appstats.stats['featured_ecpm'].map { |i| i / 100.0 } ],
              :stringData => [ @appstats.stats['featured_revenue'].map { |i| number_to_currency(i / 100.0) },
                               @appstats.stats['featured_ecpm'].map { |i| number_to_currency(i / 100.0) } ],
              :totals => [ number_to_currency(@appstats.stats['featured_revenue'].sum / 100.0),
                           @appstats.stats['featured_offers_shown'].sum > 0 ? number_to_currency(@appstats.stats['featured_revenue'].sum.to_f / (@appstats.stats['featured_offers_shown'].sum / 1000.0) / 100.0) : '$0.00' ]
            },
            :extra => {
              :names => [ 'Fill rate', 'CTR', 'CVR' ],
              :data => [ @appstats.stats['featured_fill_rate'].map { |r| "%.0f%" % (r.to_f * 100.0) },
                         @appstats.stats['featured_ctr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
                         @appstats.stats['featured_cvr'].map { |r| "%.0f%" % (r.to_f * 100.0) } ],
              :totals => [ @appstats.stats['featured_offers_requested'].sum > 0 ? ("%.1f%" % (@appstats.stats['featured_offers_shown'].sum.to_f / @appstats.stats['featured_offers_requested'].sum * 100.0)) : '-',
                           @appstats.stats['featured_offers_shown'].sum > 0 ? ("%.1f%" % (@appstats.stats['featured_offers_opened'].sum.to_f / @appstats.stats['featured_offers_shown'].sum * 100.0)) : '-',
                           @appstats.stats['featured_offers_opened'].sum > 0 ? ("%.1f%" % (@appstats.stats['featured_published_offers'].sum.to_f / @appstats.stats['featured_offers_opened'].sum * 100.0)) : '-' ]
            }
          },

          :display_ads_data => {
            :name => 'Display ads',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Ads requested', 'Ads shown', 'Clicks', 'Conversions' ],
              :data => [ @appstats.stats['display_ads_requested'], 
                         @appstats.stats['display_ads_shown'],
                         @appstats.stats['display_clicks'],
                         @appstats.stats['display_conversions'] ],
              :totals => [ @appstats.stats['display_ads_requested'].sum,
                           @appstats.stats['display_ads_shown'].sum,
                           @appstats.stats['display_clicks'].sum,
                           @appstats.stats['display_conversions'].sum ]
            },
            :right => {
              :unitPrefix => '$',
              :names => [ 'Revenue', 'eCPM' ],
              :data => [ @appstats.stats['display_revenue'].map { |i| i / 100.0 },
                         @appstats.stats['display_ecpm'].map { |i| i / 100.0 } ],
              :stringData => [ @appstats.stats['display_revenue'].map { |i| number_to_currency(i / 100.0) },
                               @appstats.stats['display_ecpm'].map { |i| number_to_currency(i / 100.0) } ],
              :totals => [ number_to_currency(@appstats.stats['display_revenue'].sum / 100.0),
                           @appstats.stats['display_ads_shown'].sum > 0 ? number_to_currency(@appstats.stats['display_revenue'].sum.to_f / (@appstats.stats['display_ads_shown'].sum / 1000.0) / 100.0) : '$0.00' ]
            },
            :extra => {
              :names => [ 'Fill rate', 'CTR', 'CVR' ],
              :data => [ @appstats.stats['display_fill_rate'].map { |r| "%.0f%" % (r.to_f * 100.0) },
                         @appstats.stats['display_ctr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
                         @appstats.stats['display_cvr'].map { |r| "%.0f%" % (r.to_f * 100.0) } ],
              :totals => [ @appstats.stats['display_ads_requested'].sum > 0 ? ("%.1f%" % (@appstats.stats['display_ads_shown'].sum.to_f / @appstats.stats['display_ads_requested'].sum * 100.0)) : '-',
                           @appstats.stats['display_ads_shown'].sum > 0 ? ("%.1f%" % (@appstats.stats['display_clicks'].sum.to_f / @appstats.stats['display_ads_shown'].sum * 100.0)) : '-',
                           @appstats.stats['display_clicks'].sum > 0 ? ("%.1f%" % (@appstats.stats['display_conversions'].sum.to_f / @appstats.stats['display_clicks'].sum * 100.0)) : '-' ]
            }
          },

          :ads_data => {
            :name => 'Ad impressions',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Ad impressions' ],
              :data => [ @appstats.stats['hourly_impressions'] ],
              :totals => [ @appstats.stats['hourly_impressions'].sum ]
            }
          },

          :granularity => @granularity,
          :date => @start_time.to_date.to_s(:mdy),
          :end_date => @end_time.to_date.to_s(:mdy)
        }

        if get_virtual_good_partitions.size > 0
          @data[:virtual_goods_data] = {
            :name => 'Virtual good purchases',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Store views', 'Total purchases' ],
              :data => [ @appstats.stats['vg_store_views'], @appstats.stats['vg_purchases'] ],
              :totals => [ @appstats.stats['vg_store_views'].sum, @appstats.stats['vg_purchases'].sum ]
            },
            :partition_names => get_virtual_good_partition_names,
            :partition_values => get_virtual_good_partition_values,
            :partition_title => 'Virtual goods',
            :partition_fallback => '',
          }
        end

        if @granularity == :daily
          @data[:connect_data][:main][:names] << 'DAUs'
          @data[:connect_data][:main][:data] << @appstats.stats['daily_active_users']
          @data[:connect_data][:main][:totals] << '-'
          @data[:connect_data][:right] = {
            :unitPrefix => '$',
            :decimals => 2,
            :names => [ 'ARPDAU' ],
            :data => [ @appstats.stats['arpdau'].map { |i| i / 100.0 } ],
            :stringData => [ @appstats.stats['arpdau'].map { |i| number_to_currency(i / 100.0, :precision => 4) } ],
            :totals => [ '-' ]
          }
        end

        if permitted_to?(:index, :statz)
          # jailbroken data
          @data[:rewarded_installs_plus_spend_data][:main][:names]  << "Jailbroken #{conversion_name}"
          @data[:rewarded_installs_plus_spend_data][:main][:data]   << @appstats.stats['jailbroken_installs']
          @data[:rewarded_installs_plus_spend_data][:main][:totals] << @appstats.stats['jailbroken_installs'].sum
        end

        render :json => { :data => @data }.to_json
      end
    end
  end

  def export
    data =  "start_time,end_time,paid_clicks,paid_installs,new_users,paid_cvr,spend,itunes_rank_overall_free_united_states,"
    data += "offerwall_views,published_offer_clicks,published_offers_completed,published_cvr,offerwall_revenue,offerwall_ecpm,display_ads_revenue,display_ads_ecpm,featured_revenue,featured_ecpm"
    data += ",daily_active_users,arpdau" if @granularity == :daily
    data = [data]

    @appstats.stats['paid_clicks'].length.times do |i|
      time_format = (@granularity == :daily) ? :mdy_ampm_utc : :mdy_ampm

      line = [
        @appstats.intervals[i].to_s(time_format),
        @appstats.intervals[i + 1].to_s(time_format),
        @appstats.stats['paid_clicks'][i],
        @appstats.stats['paid_installs'][i],
        @appstats.stats['new_users'][i],
        @appstats.stats['cvr'][i],
        number_to_currency(@appstats.stats['installs_spend'][i] / -100.0, :delimiter => ''),
        (Array(@appstats.stats['ranks']['overall.free.united_states'])[i] || '-'),
        @appstats.stats['offerwall_views'][i],
        @appstats.stats['rewards_opened'][i],
        @appstats.stats['rewards'][i],
        @appstats.stats['rewards_cvr'][i],
        number_to_currency(@appstats.stats['rewards_revenue'][i] / 100.0, :delimiter => ''),
        number_to_currency(@appstats.stats['offerwall_ecpm'][i] / 100.0, :delimiter => ''),
        number_to_currency(@appstats.stats['display_revenue'][i] / 100.0, :delimiter => ''),
        number_to_currency(@appstats.stats['display_ecpm'][i] / 100.0, :delimiter => ''),
        number_to_currency(@appstats.stats['featured_revenue'][i] /100.0, :delimiter => ''),
        number_to_currency(@appstats.stats['featured_ecpm'][i] /100.0, :delimiter => ''),
      ]

      if @granularity == :daily
        line << @appstats.stats['daily_active_users'][i]
        line << number_to_currency(@appstats.stats['arpdau'][i] / 100.0, :delimiter => '')
      end
      data << line.join(',')
    end

    send_data(data.join("\n"), :type => 'text/csv', :filename => "#{@offer.id}_#{@start_time.to_date.to_s(:db_date)}_#{@end_time.to_date.to_s(:db_date)}.csv")
  end
  
  def download_udids
    bucket = S3.bucket(BucketNames::AD_UDIDS)
    data = bucket.get(Offer.s3_udids_path(@offer.id) + params[:date])
    send_data(data, :type => 'text/csv', :filename => "#{@offer.id}_#{params[:date]}.csv")
  end
  
  def api
  end
  
  def regenerate_api_key
    current_user.regenerate_api_key
    if current_user.save
      flash[:notice] = "You have successfully regenerated your API key."
    else
      flash[:error] = "Error regenerating the API key. Please try again."
    end
    redirect_to api_reporting_path
  end
  
private
  
  def find_offer
    if permitted_to?(:index, :statz)
      @offer = Offer.find_by_id(params[:id], :include => 'item')
    else
      @offer = current_partner.offers.find_by_id(params[:id], :include => 'item')
    end
    if @offer.nil?
      flash[:notice] = 'Unknown offer id'
      redirect_to reporting_index_path and return
    end
  end
  
  def setup
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

    if (@end_time - @start_time < 1.day) && @granularity == :daily
      @start_time = @start_time.beginning_of_day
      @end_time = @end_time.end_of_day
    end

    # lookup the stats
    @appstats = Appstats.new(@offer.id, { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true })
  end
  
  def get_rank_partitions
    return @rank_partitions if defined?(@rank_partitions)
    @rank_partitions = {}
    
    keys = @appstats.stats['ranks'].keys.sort do |key1, key2|
      key1.gsub(/^overall/, '1') <=> key2.gsub(/^overall/, '1')
    end
    
    keys.each do |key|
      key_parts = key.split('.')
      country = "#{key_parts[2].titleize} (#{key_parts[1].titleize.gsub('Ipad', 'iPad')})"
      ranks = @appstats.stats['ranks'][key]
      
      @rank_partitions[country] ||= {}
      @rank_partitions[country][:yMax] = 200
      @rank_partitions[country][:names] ||= []
      @rank_partitions[country][:data] ||= []
      @rank_partitions[country][:totals] ||= []
      
      @rank_partitions[country][:names] << "#{key_parts[0].titleize}"
      @rank_partitions[country][:data] << ranks
      @rank_partitions[country][:totals] << (ranks.compact.last.ordinalize rescue '-')
    end
    
    @rank_partitions
  end
  
  def get_rank_partition_names
    get_rank_partitions.keys.sort
  end
  
  def get_rank_partition_values
    values = []
    get_rank_partition_names.each do |name|
      values << get_rank_partitions[name]
    end
    values
  end

  def get_virtual_good_partitions
    return @virtual_good_paritions if @virtual_good_paritions.present?
    @virtual_good_paritions = {}
    
    virtual_goods = @offer.virtual_goods.sort
    
    virtual_goods.each_with_index do |vg, i|
      mod = i % 5 
      upper = [i - mod + 5, virtual_goods.size].min
      group = "#{i - mod + 1} - #{upper}"
      
      @virtual_good_paritions[group] ||= {}
      @virtual_good_paritions[group][:names] ||= []
      @virtual_good_paritions[group][:longNames] ||= []
      @virtual_good_paritions[group][:data] ||= []
      @virtual_good_paritions[group][:totals] ||= []
      
      vg_name = truncate(vg.name, :length => 13)
      
      @virtual_good_paritions[group][:names] << vg_name
      @virtual_good_paritions[group][:longNames] << vg.name
      @virtual_good_paritions[group][:data] << (@appstats.stats['virtual_goods'][vg.key] || Array.new(@appstats.stats['vg_purchases'].size, 0))
      @virtual_good_paritions[group][:totals] << (@appstats.stats['virtual_goods'][vg.key].sum rescue 0)
    end
    
    @virtual_good_paritions
  end
  
  def get_virtual_good_partition_names
    get_virtual_good_partitions.keys.sort do |k1, k2|
      k1.split[0].to_i <=> k2.split[0].to_i
    end
  end
  
  def get_virtual_good_partition_values
    get_virtual_good_partition_names.map do |name|
      get_virtual_good_partitions[name]
    end
  end
  
end
