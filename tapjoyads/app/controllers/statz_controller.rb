class StatzController < WebsiteController
  layout 'tabbed'
  
  filter_access_to :all
  
  before_filter :find_offer, :only => [ :show, :edit, :update, :new, :create, :last_run_times, :udids, :download_udids ]
  after_filter :save_activity_logs, :only => [ :update ]
  
  def index
    @timeframe = params[:timeframe] || '24_hours'
    
    money_stats = Mc.get('money.cached_stats')
    @cvr_count = money_stats[@timeframe]['conversions'] rescue "Not Available"
    @ad_spend =  money_stats[@timeframe]['advertiser_spend'] rescue "Not Available"
    @publisher_earnings =  money_stats[@timeframe]['publisher_earnings'] rescue "Not Available"
    
    @last_updated = Mc.get("statz.last_updated.#{@timeframe}") || Time.at(8.hours.to_i)
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
    @associated_offers = @offer.find_associated_offers
    
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
    log_activity(@offer)
    
    orig_payment = @offer.payment
    orig_budget = @offer.daily_budget
    params[:offer][:device_types] = params[:offer][:device_types].blank? ? '[]' : params[:offer][:device_types].to_json
    params[:offer][:user_enabled] = params[:offer][:payment].to_i > 0
    if @offer.update_attributes(params[:offer])
      
      app = nil
      unless params[:app_store_id].blank?
        app = @offer.item
        orig_store_id = app.store_id
        log_activity(app)
        app.update_attribute(:store_id, params[:app_store_id])
      end
      
      if [ 'App', 'EmailOffer' ].include?(@offer.item_type) && @offer.is_primary? && (orig_payment != @offer.payment || orig_budget != @offer.daily_budget || (app && orig_store_id != app.store_id))
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
      { :udid => '5c46e034cd005e5f2b08501820ecb235b0f13f33', :last_run_time => 'Never', :device_label => 'Hwan-Joon iPhone' },
      { :udid => '05f900a2b588c4ed140689145ddb4684a1681f20', :last_run_time => 'Never', :device_label => 'Kai iPad'         },
      { :udid => 'c720dd0a5f937735c1a76bce72fcd90ada73ad7d', :last_run_time => 'Never', :device_label => 'Kai iTouch'       },
      { :udid => '713ad9936e296243725a40799bea7c15c87bb4c8', :last_run_time => 'Never', :device_label => 'Lauren iPad'      },
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
    
    @udids_to_check.each do |hash|
      list = DeviceAppList.new(:key => hash[:udid])
      if list.has_app(@offer.id)
        hash[:last_run_time] = list.last_run_time(@offer.id).in_time_zone('Pacific Time (US & Canada)').to_s(:pub_ampm_sec)
      end
    end
  end
  
  def search
    results = Offer.find(:all,
      :conditions => [ "name LIKE ?", "%#{params[:term]}%" ],
      :select => 'id, name, name_suffix, tapjoy_enabled, payment',
      :limit => 10
    ).collect do |o|
      label_string = o.name_with_suffix
      label_string += " (active)" if o.tapjoy_enabled? && o.payment > 0
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
