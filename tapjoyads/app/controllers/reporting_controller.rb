class ReportingController < WebsiteController
  include ActionView::Helpers::NumberHelper
  
  layout 'tabbed'
  
  filter_access_to :all
  before_filter :setup, :only => [ :show, :export ]
  
  def index
  end
  
  def show
  end
  
  def export
    data = "start_time,end_time,paid_clicks,paid_installs,paid_cvr,spend,offerwall_views,published_offer_clicks,published_offers_completed,published_cvr,revenue,offerwall_ecpm\n"
    
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
