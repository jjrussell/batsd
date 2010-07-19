class StatzController < WebsiteController
  
  filter_access_to [ :index, :show, :edit, :update, :search, :last_run_times ]
  
  before_filter :find_offer, :only => [ :show, :edit, :update, :last_run_times ]
  
  def index
    money_stats = Mc.get('statz.money') || {'24_hours' => {}}
    @cvr_count_24hours = money_stats['24_hours']['conversions'] || "Not Available"
    @ad_spend_24hours =  money_stats['24_hours']['advertiser_spend'] || "Not Available"
    @publisher_earnings_24hours =  money_stats['24_hours']['publisher_earnings'] || "Not Available"
    
    @last_updated = Mc.get('statz.last_updated') || Time.at(8.hours.to_i)
    @cached_stats = Mc.get('statz.cached_stats') || {}
  end
  
  def show
    now = Time.zone.now
    @start_time = now.beginning_of_hour - 23.hours
    @end_time = now
    unless params[:date].blank?
      now = Time.zone.parse(params[:date])
      @start_time = now.beginning_of_day
      @end_time = @start_time + 24.hours
    end
    @stats = Appstats.new(@offer.id, { :start_time => @start_time, :end_time => @end_time }).stats
    
    granularity = 1.hour
    @intervals = []
    @x_labels = []
    25.times do |i|
      @intervals << (@start_time + i * granularity).in_time_zone('Pacific Time (US & Canada)').to_s(:pub_ampm)
    end
    24.times do |i|
      @x_labels << (@start_time + i * granularity).in_time_zone('Pacific Time (US & Canada)').to_s(:time)
    end
  end
  
  def edit
  end
  
  def update
    params[:offer][:device_types] = params[:offer][:device_types].to_json
    if @offer.update_attributes(params[:offer])
      flash[:notice] = "Successfully updated #{@offer.name}"
      redirect_to statz_path(@offer)
    else
      render :action => :edit
    end
  end
  
  def last_run_times
    @udid_map = {
      'b4c86b4530a0ee889765a166d80492b46f7f3636' => 'Ryan iPhone',
      'f0910f7ab2a27a5d079dc9ed50d774fcab55f91d' => 'Ryan iPad',
    }
    @last_run_times = {}
    @udid_map.keys.each do |udid|
      list = DeviceAppList.new(:key => udid)
      if list.has_app(@offer.id)
        @last_run_times[udid] = list.last_run_time(@offer.id).to_s(:db)
      else
        @last_run_times[udid] = 'Never'
      end
    end
  end
  
  def search
    results = Offer.find(:all,
      :conditions => "name LIKE '%#{params[:q]}%'",
      :select => 'id, name, tapjoy_enabled, payment',
      :limit => params[:limit]
    ).collect do |o|
      result = "#{o.name}|#{o.id}"
      result = "*#{result}" if o.tapjoy_enabled? && o.payment > 0
      result
    end
    
    render(:text => results.join("\n"))  
  end
  
private
  
  def find_offer
    @offer = Offer.find(params[:id]) rescue nil
    if @offer.nil?
      flash[:error] = "Could not find an offer with ID: #{params[:id]}"
      redirect_to statz_index_path
    end
  end
  
end
