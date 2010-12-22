class ReportingController < WebsiteController
  include ActionView::Helpers::NumberHelper
  
  layout 'tabbed'
  
  filter_access_to :all
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
    flash[:error] = "We are experiencing intermittent service interruptions due to server issues, so you may notice slow response times using our web site and issues with reporting.<br/><br/>We are doing everything in our ability to resolve the issues ASAP, and should be back to 100% shortly. We apologize for the inconvenience."
    session[:last_shown_app] = @offer.item_id if @offer.item_type == 'App'

    if @granularity == :daily
      intervals = @appstats.intervals.map { |time| time.to_s(:pub) + " UTC"  }
    else
      intervals = @appstats.intervals.map { |time| time.to_s(:pub_ampm) }
    end

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
            :name => 'Paid installs + Advertising spend',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Paid installs', 'Paid clicks' ],
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
            :name => 'Paid installs + Rank',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Paid installs', 'Paid clicks' ],
              :data => [ @appstats.stats['paid_installs'], @appstats.stats['paid_clicks'] ],
              :totals => [ @appstats.stats['paid_installs'].sum, @appstats.stats['paid_clicks'].sum ]
            },
            :right => {
              :yMax => 200,
              :names => [ 'Rank' ],
              :data => [ @appstats.stats['overall_store_rank'].map { |r| r == '-' || r == '0' ? nil : r } ],
              :totals => [ (@appstats.stats['overall_store_rank'].select { |r| r != '0' }.last || '-') ]
            }
          },

          :published_offers_data => {
            :name => 'Revenue',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Offers completed', 'Offer clicks' ],
              :data => [ @appstats.stats['rewards'], @appstats.stats['rewards_opened'] ],
              :totals => [ @appstats.stats['rewards'].sum, @appstats.stats['rewards_opened'].sum ]
            },
            :right => {
              :unitPrefix => '$',
              :names => [ 'Revenue' ],
              :data => [ @appstats.stats['rewards_revenue'].map { |i| i / 100.0 } ],
              :stringData => [ @appstats.stats['rewards_revenue'].map { |i| number_to_currency(i / 100.0) } ],
              :totals => [ number_to_currency(@appstats.stats['rewards_revenue'].sum / 100.0) ]
            },
            :extra => {
              :names => [ 'Conversion rate' ],
              :data => [ @appstats.stats['rewards_cvr'].map { |cvr| "%.0f%" % (cvr.to_f * 100.0) } ],
              :totals => [ @appstats.stats['rewards_opened'].sum > 0 ? ("%.1f%" % (@appstats.stats['rewards'].sum.to_f / @appstats.stats['rewards_opened'].sum * 100.0)) : '-' ]
            }
          },

          :offerwall_views_data => {
            :name => 'Offerwall views',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Offerwall views' ],
              :data => [ @appstats.stats['offerwall_views'] ],
              :totals => [ @appstats.stats['offerwall_views'].sum ]
            },
            :right => {
              :unitPrefix => '$',
              :names => [ 'Offerwall eCPM' ],
              :data => [ @appstats.stats['offerwall_ecpm'].map { |i| i / 100.0 } ],
              :stringData => [ @appstats.stats['offerwall_ecpm'].map { |i| number_to_currency(i / 100.0) } ],
              :totals => [ @appstats.stats['offerwall_views'].sum > 0 ? number_to_currency(@appstats.stats['rewards_revenue'].sum.to_f / (@appstats.stats['offerwall_views'].sum / 1000.0) / 100.0) : '$0.00' ]
            }
          },

          :display_ads_data => {
            :name => 'Display ads',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Ads requested', 'Ads shown', 'Clicks', 'Conversions' ],
              :data => [ @appstats.stats['display_ads_requested'], @appstats.stats['display_ads_shown'], @appstats.stats['display_clicks'], @appstats.stats['display_conversions'] ],
              :totals => [ @appstats.stats['display_ads_requested'].sum, @appstats.stats['display_ads_shown'].sum, @appstats.stats['display_clicks'].sum, @appstats.stats['display_conversions'].sum ]
            },
            :right => {
              :unitPrefix => '$',
              :names => [ 'Revenue', 'eCPM' ],
              :data => [ @appstats.stats['display_revenue'].map { |i| i / 100.0 }, @appstats.stats['display_ecpm'].map { |i| i / 100.0 } ],
              :stringData => [ @appstats.stats['display_revenue'].map { |i| number_to_currency(i / 100.0) }, @appstats.stats['display_ecpm'].map { |i| number_to_currency(i / 100.0) } ],
              :totals => [ number_to_currency(@appstats.stats['display_revenue'].sum / 100.0), @appstats.stats['display_ads_shown'].sum > 0 ? number_to_currency(@appstats.stats['display_revenue'].sum.to_f / (@appstats.stats['display_ads_shown'].sum / 1000.0) / 100.0) : '$0.00' ]
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

          :virtual_goods_data => {
            :name => 'Virtual Goods',
            :intervals => intervals,
            :xLabels => @appstats.x_labels,
            :main => {
              :names => [ 'Virtual good purchases' ],
              :data => [ @appstats.stats['vg_purchases'] ],
              :totals => [ @appstats.stats['vg_purchases'].sum ]
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
          @data[:rewarded_installs_plus_spend_data][:main][:names]  << 'Jailbroken installs'
          @data[:rewarded_installs_plus_spend_data][:main][:data]   << @appstats.stats['jailbroken_installs']
          @data[:rewarded_installs_plus_spend_data][:main][:totals] << @appstats.stats['jailbroken_installs'].sum
        end

        render :json => {
          :data => @data,
          :stats_table => render_to_string(:action => '_stats_table.html.haml')
        }.to_json
      end
    end
  end

  def export
    data =  "start_time,end_time,paid_clicks,paid_installs,new_users,paid_cvr,spend,store_rank,"
    data += "offerwall_views,published_offer_clicks,published_offers_completed,published_cvr,revenue,offerwall_ecpm"
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
        @appstats.stats['overall_store_rank'][i],
        @appstats.stats['offerwall_views'][i],
        @appstats.stats['rewards_opened'][i],
        @appstats.stats['rewards'][i],
        @appstats.stats['rewards_cvr'][i],
        number_to_currency(@appstats.stats['rewards_revenue'][i] / 100.0, :delimiter => ''),
        number_to_currency(@appstats.stats['offerwall_ecpm'][i] / 100.0, :delimiter => '')
      ]

      if @granularity == :daily
        line << @appstats.stats['daily_active_users'][i]
        line << number_to_currency(@appstats.stats['arpdau'][i] / 100.0, :delimiter => '')
      end
      data << line.join(',')
    end

    send_data(data.join("\n"), :type => 'text/csv', :filename => "#{@offer.id}_#{@start_time.to_date.to_s(:db_date)}_#{@end_time.to_date.to_s(:db_date)}.csv")
  end
  
private
  
  def setup
    # find the offer
    if permitted_to?(:index, :statz)
      @offer = Offer.find_by_id(params[:id], :include => 'item')
    else
      @offer = current_partner.offers.find_by_id(params[:id], :include => 'item')
    end
    if @offer.nil?
      flash[:notice] = 'Unknown offer id'
      redirect_to reporting_index_path and return
    end
    
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
  
end
