class ReportingController < WebsiteController
  include ActionView::Helpers::NumberHelper
  
  layout 'tabbed'
  
  filter_access_to :all
  before_filter :setup, :only => [ :show, :export ]
  
  def index
  end
  
  def show
    @intervals = []
    @x_labels = []
    
    time = @start_time
    while time < @end_time
      @intervals << time.to_s(:pub_ampm)
      
      if @granularity == :daily
        @x_labels << time.strftime('%m-%d')
      else
        @x_labels << time.to_s(:time)
      end
      
      time += @granularity_interval
    end
    
    if @x_labels.size > 30
      skip_every = @x_labels.size / 30
      @x_labels.size.times do |i|
        if i % (skip_every + 1) != 0
          @x_labels[i] = nil
        end
      end
    end
    
    @intervals << time.to_s(:pub_ampm)
  end
  
  def export
    data = "paid_clicks,paid_installs,paid_cvr,spend,offerwall_views,published_offer_clicks,published_offers_completed,published_cvr,revenue\n"
    
    @stats['paid_clicks'].length.times do |i|
      line =  "#{@stats['paid_clicks'][i]},"
      line += "#{@stats['paid_installs'][i]},"
      line += "#{"%.1f%" % (@stats['paid_installs'][i].to_f / @stats['paid_clicks'][i] * 100.0)},"
      line += "#{number_to_currency(@stats['installs_spend'][i] / 100.0, :delimiter => '')},"
      line += "#{@stats['offerwall_views'][i]},"
      line += "#{@stats['installs_opened'][i] + @stats['offers_opened'][i]},"
      line += "#{@stats['published_installs'][i] + @stats['offers'][i]},"
      line += "#{"%.1f%" % ((@stats['published_installs'][i] + @stats['offers'][i]).to_f / (@stats['installs_opened'][i] + @stats['offers_opened'][i]) * 100.0)},"
      line += "#{number_to_currency(@stats['installs_revenue'][i] / 100.0, :delimiter => '')}"
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
      @granularity_interval = 1.day
    else
      @granularity = :hourly
      @granularity_interval = 1.hour
    end
    
    # lookup the stats
    @stats = Appstats.new(@offer.id, { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity }).stats
  end
  
end
