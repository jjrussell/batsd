class StatzController < WebsiteController
  include ActionView::Helpers::NumberHelper
  
  layout 'tabbed'
  
  filter_access_to :all
  
  before_filter :find_offer, :only => [ :show, :edit, :update, :new, :create, :last_run_times, :udids ]
  after_filter :save_activity_logs, :only => [ :update ]
  
  def index
    @timeframe = params[:timeframe] || '24_hours'
    
    @money_stats = Mc.get('money.cached_stats') || { @timeframe => {} }
    @money_last_updated = Time.zone.at(Mc.get("money.last_updated") || 0)
    
    @last_updated = Time.zone.at(Mc.get("statz.last_updated.#{@timeframe}") || 0)
    @cached_stats = Mc.distributed_get("statz.cached_stats.#{@timeframe}") || []
  end

  def udids
    bucket = S3.bucket(BucketNames::AD_UDIDS)
    base_path = Offer.s3_udids_path(@offer.id)
    @keys = bucket.keys('prefix' => base_path).map do |key|
      key.name.gsub(base_path, '')
    end
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

    @associated_offers = @offer.find_associated_offers
    @active_boosts = @offer.rank_boosts.active
    @total_boost = @active_boosts.map(&:amount).sum
  end

  def update
    log_activity(@offer)
    offer_params = sanitize_currency_params(params[:offer], [ :bid, :min_bid_override ])
    offer_params[:device_types] = offer_params[:device_types].blank? ? '[]' : offer_params[:device_types].to_json
    if @offer.update_attributes(offer_params)
      
      unless params[:app_store_id].blank?
        app = @offer.item
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
    android_devices = [
        { :udid => '359116032048366',                          :device_label => 'Hwan-Joon HTC G2' },
        { :udid => 'a00000155c5106',                           :device_label => 'Linda Droid'      },
        { :udid => '354957031929568',                          :device_label => 'Linda Nexus One'  },
        { :udid => '355031040294361',                          :device_label => 'Linda Nexus S'    },
        { :udid => 'a100000d9833c5',                           :device_label => 'Stephen Evo'      },
        { :udid => 'a000002256c234',                           :device_label => 'Steve Droid X'    },
    ]
    ios_devices = [
        { :udid => 'ade749ccc744336ad81cbcdbf36a5720778c6f13', :device_label => 'Amir iPhone'      },
        { :udid => 'c73e730913822be833766efffc7bb1cf239d855a', :device_label => 'Ben iPhone'       },
        { :udid => '9ac478517b48da604bdb9fc15a3e48139d59660d', :device_label => 'Christine iPhone' },
        { :udid => 'f3de44744a306beb47407b9a23cd97d9fe03339a', :device_label => 'Christine iPad'   },
        { :udid => '12910a92ab2917da99b8e3c785136af56b08c271', :device_label => 'Chris iPhone'     },
        { :udid => '20c56f0606cc34f56525bb9ca03dcd0a43d70c60', :device_label => 'Dan iPhone'       },
        { :udid => '5c46e034cd005e5f2b08501820ecb235b0f13f33', :device_label => 'Hwan-Joon iPhone' },
        { :udid => 'cb76136c7362206edad3d485a1dbd51bee52cd1f', :device_label => 'Hwan-Joon iPad'   },
        { :udid => 'c163a3b343fbe6d04f9a8cda62e807c0b407f533', :device_label => 'Hwan-Joon iTouch' },
        { :udid => 'cb7907c2a762ea979a3ec38827a165e834a2f7f9', :device_label => 'Johnny iPhone'    },
        { :udid => '05f900a2b588c4ed140689145ddb4684a1681f20', :device_label => 'Kai iPad'         },
        { :udid => 'c720dd0a5f937735c1a76bce72fcd90ada73ad7d', :device_label => 'Kai iTouch'       },
        { :udid => '5eab794d002ab9b25ee54b4c792bbcde68406b57', :device_label => 'Katherine iPhone' },
        { :udid => '4b910938aceaa723e0c0313aa7fa9f9d838a595e', :device_label => 'Linda iPad'       },
        { :udid => '820a1b9df38f3024f9018464c05dfbad5708f81e', :device_label => 'Linda iPhone'     },
        { :udid => '5941f307a0f88912b0c84e075c833a24557a7602', :device_label => 'Marc iPad'        },
        { :udid => 'b4c86b4530a0ee889765a166d80492b46f7f3636', :device_label => 'Ryan iPhone'      },
        { :udid => 'f0910f7ab2a27a5d079dc9ed50d774fcab55f91d', :device_label => 'Ryan iPad'        },
        { :udid => 'cb662f568a4016a5b2e0bd617e53f70480133290', :device_label => 'Stephen iPad'     },
        { :udid => 'c1bd5bd17e35e00b828c605b6ae6bf283d9bafa1', :device_label => 'Stephen iTouch'   },
        { :udid => '2e75bbe138c85e6dc8bd8677220ef8898f40a1c7', :device_label => 'Sunny iPhone'     },
    ]
    @udids_to_check = []
    targeted_devices = @offer.get_device_types
    @udids_to_check += android_devices if Offer::ANDROID_DEVICES.any? { |device_type| targeted_devices.include?(device_type) }
    @udids_to_check += ios_devices     if Offer::APPLE_DEVICES.any?   { |device_type| targeted_devices.include?(device_type) }
    @udids_to_check.sort! { |a, b| a[:device_label] <=> b[:device_label] }
    
    unless params[:other_udid].blank?
      @udids_to_check.unshift({ :udid => params[:other_udid].downcase, :device_label => 'Other UDID' })
    end
    
    @udids_to_check.each do |hash|
      device = Device.new(:key => hash[:udid])
      hash[:last_run_time] = device.has_app(@offer.item_id) ? device.last_run_time(@offer.item_id).to_s(:pub_ampm_sec) : 'Never'
    end
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
