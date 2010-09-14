class ReportingController < WebsiteController
  include ActionView::Helpers::NumberHelper
  
  layout 'tabbed'
  
  filter_access_to :all
  before_filter :setup, :only => [ :show, :export ]
  
  def index
    unless current_partner_offers.empty?
      redirect_to reporting_path(current_partner_offers.first)
    end
  end
  
  def show
    intervals = @appstats.intervals.map { |time| time.to_s(:pub_ampm) }
    
    @connect_data = {
      :name => 'Connects',
      :intervals => intervals,
      :xLabels => @appstats.x_labels,
      :main => {
        :names => [ 'Connects', 'New Users' ],
        :data => [ @appstats.stats['logins'], @appstats.stats['new_users'] ]
      }
    }
    if @granularity == :daily
      @connect_data[:main][:names] << 'DAUs'
      @connect_data[:main][:data] << @appstats.stats['daily_active_users']
      @connect_data[:right] = {
        :unitPrefix => '$',
        :decimals => 2,
        :names => [ 'ARPDAU' ],
        :data => [ @appstats.stats['arpdau'].map { |i| i / 100.0 } ],
        :stringData => [ @appstats.stats['arpdau'].map { |i| number_to_currency(i / 100.0) } ]
      }
    end
    
    @rewarded_installs_plus_spend_data = {
      :name => 'Rewarded installs + spend',
      :intervals => intervals,
      :xLabels => @appstats.x_labels,
      :main => {
        :names => [ 'Paid installs', 'Paid clicks' ],
        :data => [ @appstats.stats['paid_installs'], @appstats.stats['paid_clicks'] ]
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Spend' ],
        :data => [ @appstats.stats['installs_spend'].map { |i| i / -100.0 } ],
        :stringData => [ @appstats.stats['installs_spend'].map { |i| number_to_currency(i / -100.0) } ]
      },
      :extra => {
        :names => [ 'Conversion rate' ],
        :data => [ @appstats.stats['cvr'].map { |cvr| "%.0f%" % (cvr.to_f * 100.0) } ]
      }
    }
    
    @rewarded_installs_plus_rank_data = {
      :name => 'Rewarded installs + rank',
      :intervals => intervals,
      :xLabels => @appstats.x_labels,
      :main => {
        :names => [ 'Paid installs', 'Paid clicks' ],
        :data => [ @appstats.stats['paid_installs'], @appstats.stats['paid_clicks'] ]
      },
      :right => {
        :yMax => 100,
        :names => [ 'Rank' ],
        :data => [ @appstats.stats['overall_store_rank'].map { |r| r == '-' || r == '0' ? nil : r } ]
      }
    }
    
    @published_offers_data = {
      :name => 'Published offers',
      :intervals => intervals,
      :xLabels => @appstats.x_labels,
      :main => {
        :names => [ 'Offers Completed', 'Offer clicks' ],
        :data => [ @appstats.stats['rewards'], @appstats.stats['rewards_opened'] ]
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Revenue' ],
        :data => [ @appstats.stats['rewards_revenue'].map { |i| i / 100.0 } ],
        :stringData => [ @appstats.stats['rewards_revenue'].map { |i| number_to_currency(i / 100.0) } ]
      },
      :extra => {
        :names => [ 'Conversion rate' ],
        :data => [ @appstats.stats['rewards_cvr'].map { |cvr| "%.0f%" % (cvr.to_f * 100.0) } ]
      }
    }
    
    @offerwall_views_data = {
      :name => 'Offerwall views',
      :intervals => intervals,
      :xLabels => @appstats.x_labels,
      :main => {
        :names => [ 'Offerwall views' ],
        :data => [ @appstats.stats['offerwall_views'] ]
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Offerwall eCPM' ],
        :data => [ @appstats.stats['offerwall_ecpm'].map { |i| i / 100.0 } ],
        :stringData => [ @appstats.stats['offerwall_ecpm'].map { |i| number_to_currency(i / 100.0) } ]
      }
    }
  end
  
  def export
    data =  "start_time,end_time,paid_clicks,paid_installs,paid_cvr,spend,"
    data += "offerwall_views,published_offer_clicks,published_offers_completed,published_cvr,revenue,offerwall_ecpm"
    data += ",daily_active_users,arpdau" if @granularity == :daily
    data += "\n"
    
    @appstats.stats['paid_clicks'].length.times do |i|
      line =  "#{@appstats.intervals[i].to_s(:db)},"
      line += "#{@appstats.intervals[i + 1].to_s(:db)},"
      line += "#{@appstats.stats['paid_clicks'][i]},"
      line += "#{@appstats.stats['paid_installs'][i]},"
      line += "#{@appstats.stats['cvr'][i]},"
      line += "#{number_to_currency(@appstats.stats['installs_spend'][i] / -100.0, :delimiter => '')},"
      line += "#{@appstats.stats['offerwall_views'][i]},"
      line += "#{@appstats.stats['rewards_opened'][i]},"
      line += "#{@appstats.stats['rewards'][i]},"
      line += "#{@appstats.stats['rewards_cvr'][i]},"
      line += "#{number_to_currency(@appstats.stats['rewards_revenue'][i] / 100.0, :delimiter => '')},"
      line += "#{number_to_currency(@appstats.stats['offerwall_ecpm'][i] / 100.0, :delimiter => '')}"
      if @granularity == :daily
        line += ",#{@appstats.stats['daily_active_users'][i]}"
        line += ",#{number_to_currency(@appstats.stats['arpdau'][i] / 100.0, :delimiter => '')}"
      end
      data += "#{line}\n"
    end
    
    send_data(data, :type => 'text/csv', :filename => "#{@offer.id}_#{@start_time.to_date.to_s(:db_date)}_#{@end_time.to_date.to_s(:db_date)}.csv")
  end
  
private
  
  def setup
    # find the offer
    @offer = current_partner.offers.find_by_id(params[:id])
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
    
    # lookup the stats
    @appstats = Appstats.new(@offer.id, { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true })
  end
  
end
