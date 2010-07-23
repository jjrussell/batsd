class StatzController < WebsiteController
  layout 'tabbed'
  
  filter_access_to :all
  
  before_filter :find_offer, :only => [ :show, :edit, :update, :last_run_times, :udids, :udid ]
  
  def index
    money_stats = Mc.get('statz.money') || {'24_hours' => {}}
    @cvr_count_24hours = money_stats['24_hours']['conversions'] || "Not Available"
    @ad_spend_24hours =  money_stats['24_hours']['advertiser_spend'] || "Not Available"
    @publisher_earnings_24hours =  money_stats['24_hours']['publisher_earnings'] || "Not Available"
    
    @last_updated = Mc.get('statz.last_updated') || Time.at(8.hours.to_i)
    @cached_stats = Mc.get('statz.cached_stats') || {}
  end
  
  def udids
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'ad-udids')
    @keys = bucket.keys('prefix' => App.udid_s3_key(@offer.id))
  end

  def udid
    @date = if params[:date]
        Time.zone.parse(params[:date] + "-01") rescue Time.zone.now
      else
        Time.zone.now
      end
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'ad-udids')
    @udids = bucket.get(App.udid_s3_key(@offer.id, @date))

    send_data(@udids,
              :type => "text/csv",
              :filename => "#{@offer.id}.#{@date.strftime("%Y-%m")}.csv",
              :disposition => "attachment")
  end

  def show
    now = Time.zone.now
    @start_time = now.beginning_of_hour - 23.hours
    @end_time = now
    unless params[:date].blank?
      @start_time = Time.zone.parse(params[:date]).beginning_of_day
      @start_time = now.beginning_of_hour - 23.hours if @start_time > now
      @end_time = @start_time + 24.hours
    end
    
    unless params[:end_date].blank?
      @end_time = Time.zone.parse(params[:end_date]).beginning_of_day
      @end_time = now if @end_time <= @start_time
    end
    
    if params[:granularity] == 'daily'
      @granularity = :daily
      granularity_interval = 1.day
    else
      @granularity = :hourly
      granularity_interval = 1.hour
    end
    
    @stats = Appstats.new(@offer.id, { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity }).stats
    
    @intervals = []
    @x_labels = []
    
    time = @start_time
    while time < @end_time
      @intervals << time.to_s(:pub_ampm)
      
      if params[:granularity] == 'daily'
        @x_labels << time.strftime('%m-%d')
      else
        @x_labels << time.to_s(:time)
      end
      
      time += granularity_interval
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
      '21e3f395b9bbaf56667782ea3fe1241656684e21' => 'Stephen iTouch',
      'c720dd0a5f937735c1a76bce72fcd90ada73ad7d' => 'Kai iTouch',
      '4b910938aceaa723e0c0313aa7fa9f9d838a595e' => 'Linda iPad',
      '820a1b9df38f3024f9018464c05dfbad5708f81e' => 'Linda iPhone',
      'c73e730913822be833766efffc7bb1cf239d855a' => 'Ben iPhone',
      '713ad9936e296243725a40799bea7c15c87bb4c8' => 'Lauren iPad'
    }
    @last_run_times = {}
    @udid_map.keys.each do |udid|
      list = DeviceAppList.new(:key => udid)
      if list.has_app(@offer.id)
        @last_run_times[udid] = list.last_run_time(@offer.id).in_time_zone('Pacific Time (US & Canada)').to_s(:pub_ampm_sec)
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
