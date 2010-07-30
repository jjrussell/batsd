class StatzController < WebsiteController
  layout 'tabbed'
  
  filter_access_to :all
  
  around_filter :log_activity, :only => [ :update ]
  before_filter :find_offer, :only => [ :show, :edit, :update, :last_run_times, :udids, :udid ]
  
  def index
    money_stats = Mc.get('money.cached_stats') || {'24_hours' => {}}
    @cvr_count_24hours = money_stats['24_hours']['conversions'] || "Not Available"
    @ad_spend_24hours =  money_stats['24_hours']['advertiser_spend'] || "Not Available"
    @publisher_earnings_24hours =  money_stats['24_hours']['publisher_earnings'] || "Not Available"
    
    @last_updated = Mc.get('statz.last_updated') || Time.at(8.hours.to_i)
    @cached_stats = Mc.get('statz.cached_stats') || {}
  end
  
  def udids
    bucket = S3.bucket(BucketNames::AD_UDIDS)
    @keys = bucket.keys('prefix' => App.udid_s3_key(@offer.id))
  end

  def udid
    @date = if params[:date]
        Time.zone.parse(params[:date] + "-01") rescue Time.zone.now
      else
        Time.zone.now
      end
    bucket = S3.bucket(BucketNames::AD_UDIDS)
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
      @end_time = Time.zone.parse(params[:end_date]).end_of_day
      @end_time = now if @end_time <= @start_time
    end
    
    if params[:granularity] == 'daily' || @end_time - @start_time > 7.days
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
      
      if @granularity == :daily
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
    @activity_log.add_state_object(@offer)
    
    orig_payment = @offer.payment
    orig_budget = @offer.daily_budget
    params[:offer][:device_types] = params[:offer][:device_types].to_json
    if @offer.update_attributes(params[:offer])
      
      app = nil
      unless params[:app_store_id].blank?
        app = @offer.item
        orig_store_id = app.store_id
        @activity_log.add_state_object(app)
        app.update_attribute(:store_id, params[:app_store_id])
      end
      
      if [ 'App', 'EmailOffer' ].include?(@offer.item_type) && (orig_payment != @offer.payment || orig_budget != @offer.daily_budget || (app && orig_store_id != app.store_id))
        mssql_url = 'http://www.tapjoyconnect.com.asp1-3.dfw1-1.websitetestlink.com/Service1.asmx/SetAppData?Password=stephenisawesome'
        mssql_url += "&AppID=#{@offer.id}"
        mssql_url += "&Payment=#{@offer.payment}"
        mssql_url += "&Budget=#{@offer.daily_budget}"
        mssql_url += "&URL="
        mssql_url += "#{CGI::escape(app.mssql_store_url)}" unless app.nil?
        
        Downloader.get_with_retry(mssql_url, {:timeout => 30}) if Rails.env == 'production'
      end
      
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
      '05f900a2b588c4ed140689145ddb4684a1681f20' => 'Kai iPad',
      '4b910938aceaa723e0c0313aa7fa9f9d838a595e' => 'Linda iPad',
      '820a1b9df38f3024f9018464c05dfbad5708f81e' => 'Linda iPhone',
      'c73e730913822be833766efffc7bb1cf239d855a' => 'Ben iPhone',
      '713ad9936e296243725a40799bea7c15c87bb4c8' => 'Lauren iPad',
      '5c46e034cd005e5f2b08501820ecb235b0f13f33' => 'Hwan-Joon iPhone',
      'a00000155c5106'                           => 'Linda Droid',
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
      :conditions => "name LIKE '%#{params[:term]}%'",
      :select => 'id, name, tapjoy_enabled, payment',
      :limit => 10
    ).collect do |o|
      label_string = o.name
      label_string += " (active)" if o.tapjoy_enabled? && o.payment > 0
      { :label => label_string, :url => statz_path(o) }
    end
    
    render(:json => results.to_json)  
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
