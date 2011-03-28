class ToolsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all

  after_filter :save_activity_logs, :only => [ :update_user, :update_android_app, :update_device, :resolve_clicks ]

  def index
  end

  def new_transfer
  end

  def monthly_data
    @period = Date.current - 1.month
    @period = Date.parse(params[:period]) unless params[:period].blank?

    month = @period.month
    year  = @period.year
    @months = []
    date = Date.parse('2009-06-01') #the first month of the platform
    while (date < Date.current.beginning_of_month) do
      @months << date.strftime('%b %Y')
      date += 1.month
    end

    conditions = [ "month = ? and year = ? and id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'", month, year ]
    MonthlyAccounting.using_slave_db do
      @spend      = MonthlyAccounting.sum(:spend,             :conditions => conditions) /-100.0
      @marketing  = MonthlyAccounting.sum(:marketing_orders,  :conditions => conditions) / 100.0
      @new_orders = MonthlyAccounting.sum(:website_orders,    :conditions => conditions) / 100.0 +
                    MonthlyAccounting.sum(:invoiced_orders,   :conditions => conditions) / 100.0
      @transfers  = MonthlyAccounting.sum(:transfer_orders,   :conditions => conditions) / 100.0
      @earnings   = MonthlyAccounting.sum(:earnings,          :conditions => conditions) / 100.0
      @payouts    = MonthlyAccounting.sum(:payment_payouts,   :conditions => conditions) /-100.0
    end

    @linkshare_est = @spend.to_f * 0.026
    @ads_est = 400.0 * 30
    @revenue = @spend + @linkshare_est + @ads_est - @marketing
    @net_revenue = @revenue - @earnings
    @margin = @net_revenue.to_f * 100.0 / @revenue.to_f
  end

  def money
    @money_stats = Mc.get('money.cached_stats') || {}
    @last_updated = Time.zone.at(Mc.get('money.last_updated') || 0)
    @total_balance = Mc.get('money.total_balance') || 0
    @total_pending_earnings = Mc.get('money.total_pending_earnings') || 0
  end
  
  def send_currency_failures
    @now               = Time.zone.now
    this_hour_mc_time  = @now.to_i / 1.hour
    last_hour_mc_time  = this_hour_mc_time - 1
    this_hour_failures = Mc.get("send_currency_failures.#{this_hour_mc_time}") { {} }
    last_hour_failures = Mc.get("send_currency_failures.#{last_hour_mc_time}") { {} }
    
    @failures         = []
    @this_hour_total  = 0
    @last_hour_total  = 0
    @this_hour_unique = 0
    @last_hour_unique = 0
    Currency.find((this_hour_failures.keys + last_hour_failures.keys).uniq, :include => :app).each do |currency|
      hash                    = {}
      hash[:currency]         = currency
      hash[:this_hour_total]  = Mc.get_count("send_currency_failure.#{currency.id}.#{this_hour_mc_time}")
      hash[:last_hour_total]  = Mc.get_count("send_currency_failure.#{currency.id}.#{last_hour_mc_time}")
      hash[:this_hour_unique] = (this_hour_failures[currency.id] || []).length
      hash[:last_hour_unique] = (last_hour_failures[currency.id] || []).length
      
      @failures << hash
      @this_hour_total  += hash[:this_hour_total]
      @last_hour_total  += hash[:last_hour_total]
      @this_hour_unique += hash[:this_hour_unique]
      @last_hour_unique += hash[:last_hour_unique]
    end
  end
  
  def failed_sdb_saves
    @bad_web_requests = Mc.get('failed_sdb_saves.bad_domains') || {}
    @failed_sdb_saves = {}

    this_hour_key = (Time.zone.now.to_f / 1.hour).to_i
    last_hour_key = ((Time.zone.now.to_f - 1.hour) / 1.hour).to_i

    SimpledbResource.get_domain_names.each do |domain_name|
      sdb_this_hour_count         = Mc.get_count("failed_sdb_saves.sdb.#{domain_name}.#{this_hour_key}")
      sdb_last_hour_count         = Mc.get_count("failed_sdb_saves.sdb.#{domain_name}.#{last_hour_key}")
      mc_this_hour_count          = Mc.get_count("failed_sdb_saves.mc.#{domain_name}.#{this_hour_key}")
      mc_last_hour_count          = Mc.get_count("failed_sdb_saves.mc.#{domain_name}.#{last_hour_key}")

      @failed_sdb_saves[domain_name] = { :sdb_this_hour => sdb_this_hour_count,
                                         :sdb_last_hour         => sdb_last_hour_count,
                                         :mc_this_hour          => mc_this_hour_count,
                                         :mc_last_hour          => mc_last_hour_count }
    end
  end

  def sdb_metadata
    @metadata = {}
    SimpledbResource.get_domain_names.each do |domain_name|
      begin
        @metadata[domain_name] = SimpledbResource.sdb.domain_metadata(domain_name)
      rescue RightAws::AwsError
        # do nothing
      end
    end
  end

  def sqs_lengths
    @queues = Sqs.sqs.queues
  end

  def elb_status
    elb_interface  = RightAws::ElbInterface.new
    ec2_interface  = RightAws::Ec2.new
    @lb_names      = Rails.env == 'production' ? %w( masterjob-lb job-lb website-lb web-lb test-lb ) : []
    @lb_instances  = {}
    @ec2_instances = {}
    @lb_names.each do |lb_name|
      @lb_instances[lb_name] = elb_interface.describe_instance_health(lb_name)
      instance_ids = @lb_instances[lb_name].map { |i| i[:instance_id] }
      instance_ids.in_groups_of(70) do |instances|
        instances.compact!
        ec2_interface.describe_instances(instances).each do |instance|
          @ec2_instances[instance[:aws_instance_id]] = instance
        end
      end
      
      @lb_instances[lb_name].sort! { |a, b| a[:instance_id] <=> b[:instance_id] }
    end
  end

  def as_groups
    as_interface = RightAws::AsInterface.new
    @as_groups = as_interface.describe_auto_scaling_groups
    @as_groups.each do |group|
      group[:triggers] = as_interface.describe_triggers(group[:auto_scaling_group_name])
    end
    @as_groups.sort! { |a, b| a[:auto_scaling_group_name] <=> b[:auto_scaling_group_name] }
  end

  def disabled_popular_offers
    @offers_count_hash = Mc.distributed_get('tools.disabled_popular_offers') { {} }
    @offers = Offer.find(@offers_count_hash.keys, :include => [:partner, :item])
  end

  def reset_device
    if params[:udid]
      udid = params[:udid].downcase
      clicks_deleted = 0
      
      device = Device.new(:key => udid)
      NUM_CLICK_DOMAINS.times do |i|
        Click.select(:domain_name => "clicks_#{i}", :where => "itemName() like '#{udid}.%'") do |click|
          click.delete_all
          clicks_deleted += 1
        end
      end
        
      device.delete_all
      flash.now[:notice] = "Device successfully reset and #{clicks_deleted} clicks deleted"
    end
  end

  def device_info
    if params[:udid]
      udid = params[:udid].downcase
      @device = Device.new(:key => udid)
      if @device.is_new
        flash.now[:error] = "Device with ID #{udid} not found"
        @device = nil
        return
      end
      conditions = "itemName() like '#{udid}.%'"
      @clicks = []
      @rewarded_clicks_count = 0
      click_app_ids = []
      NUM_CLICK_DOMAINS.times do |i|
        Click.select(:domain_name => "clicks_#{i}", :where => conditions) do |click|
          @clicks << click
          @rewarded_clicks_count += 1 if click.installed_at?
          click_app_ids << [click.publisher_app_id, click.advertiser_app_id, click.displayer_app_id]
        end
      end

      # find all apps at once and store in look up table
      @click_apps = {}
      Offer.find_all_by_id(click_app_ids.flatten.uniq).each do |app|
        @click_apps[app.id] = app
      end

      last_run_times = @device.apps
      @apps = Offer.find_all_by_id(@device.apps.keys).map do |app|
        [Time.zone.at(last_run_times[app.id].to_f), app]
      end.sort.reverse
      @clicks = @clicks.sort_by do |click|
        -click.clicked_at.to_f
      end

      @has_displayer = @clicks.any? do |click|
        click.displayer_app_id?
      end
    end
  end

  def update_device
    device = Device.new :key => params[:udid]
    log_activity(device)
    if params[:internal_notes].blank?
      device.delete('internal_notes') if device.internal_notes?
    else
      device.internal_notes = params[:internal_notes]
    end
    device.save
    flash[:notice] = 'Internal notes successfully updated.'
    redirect_to :action => :device_info, :udid => params[:udid]
  end

  def managed_partner_ids
    Mc.get_and_put('managed_partners', false, 1.minute) do
      User.account_managers.map(&:partners).flatten.uniq.map(&:id)
    end
  end

  def resolve_clicks
    click = Click.new(:key => params[:click_id])
    if click.new_record?
      flash[:error] = "Unknown click id."
      redirect_to unresolved_clicks_tools_path and return
    end
    log_activity(click)

    if click.currency_id.nil? # old clicks don't have currency_id
      currencies = Currency.find_all_by_app_id(click.publisher_app_id)
      if currencies.length == 1
        click.currency_id = currencies.first.id
      else
        flash[:error] = "Ambiguity -- the publisher app has more than one currency and currency_id was not specified."
        redirect_to unresolved_clicks_tools_path(:udid => click.udid) and return
      end
    end

    if click.clicked_at < Time.zone.now - 47.hours
      click.clicked_at = Time.zone.now - 1.minute
      flash[:error] = "Because the click was from 48+ hours ago this might fail. If it doesn't go through, try again in a few minutes."
    end

    click.put('manually_resolved_at', Time.zone.now.to_f.to_s)
    click.serial_save

    if Rails.env == 'production'
      Downloader.get_with_retry "#{API_URL}/connect?app_id=#{click.advertiser_app_id}&udid=#{click.udid}"
    end

    redirect_to unresolved_clicks_tools_path(:udid => click.udid)
  end

  def unresolved_clicks
    @udid = params[:udid]
    @num_hours = params[:num_hours].nil? ? 48 : params[:num_hours].to_i
    @clicks = []
    cut_off = (Time.zone.now - @num_hours.hours).to_f
    device = Device.new(:key => @udid)

    if @udid
      @udid.downcase!
      NUM_CLICK_DOMAINS.times do |i|
        Click.select(:domain_name => "clicks_#{i}", :where => "itemName() like '#{@udid}.%'", :consistent => true) do |click|
          if click.installed_at.nil? && click.clicked_at.to_f > cut_off
            @clicks << [
              click.clicked_at,
              device.last_run_time(click.advertiser_app_id),
              click]
          end
        end
      end
    end
    @clicks.sort!
  end

  def sanitize_users
    Partner.using_slave_db do
      @partners = Partner.scoped(
        :conditions => "partners.id not in ('#{managed_partner_ids.join("','")}')",
        :order => 'partners.pending_earnings DESC, partners.balance DESC',
        :include => { :offers => [], :users => [:partners]}
      ).paginate(:page => params[:page])
    end
  end

  def update_user
    @user = User.find_by_id(params[:id])
    log_activity(@user)
    email = @user.email
    @user.username = @user.email = params[:user][:email] unless params[:user][:email].blank?
    @user.can_email = params[:user][:can_email] unless params[:user][:can_email].blank?
    if @user.save
      message = {
        :type => "update",
        :email => email,
        :merge_tags => {
          'EMAIL' => @user.email,
          'CAN_EMAIL' => @user.can_email.to_s
        }
      }.to_json
      Sqs.send_message(QueueNames::MAIL_CHIMP_UPDATES, message)
      render :json => {:success => true}
    else
      render :json => {:success => false}
    end
  end

  def edit_android_app
    unless params[:id].blank?
      @app = App.find_by_id(params[:id])
      if @app.nil?
        flash.now[:error] = "Could not find Android app with ID #{params[:id]}."
      elsif @app.platform != "android"
        flash.now[:error] = "'#{@app.name}' is not an Android app."
        @app = nil
      end
    end
  end

  def update_android_app
    @app = App.find_by_id_and_platform(params[:id], "android")
    log_activity(@app)
    @app.store_id = params[:store_id] unless params[:store_id].blank?
    @app.price = params[:price].to_i

    if @app.save
      @app.download_icon(params[:url], nil) unless params[:url].blank?
      flash[:notice] = 'App was successfully updated'
      redirect_to statz_path(@app)
    else
      flash.now[:error] = 'Update unsuccessful'
      render :action => "edit_android_app"
    end
  end

  def publishers_without_payout_info
    partners_without_payout_info = Partner.to_payout_by_earnings.reject(&:completed_payout_info?)
    @count = partners_without_payout_info.length
    @partners = partners_without_payout_info.paginate(:page => params[:page])
  end

  def publisher_payout_info_changes
    if params[:month] && params[:year]
      @date_str = "#{params[:year]}-#{params[:month]}-01"
      @date = Time.parse(@date_str)
    else
      @date = Time.zone.now.beginning_of_month
      @date_str = @date.strftime('%Y-%m')
    end
    @payout_infos = PayoutInfo.recently_updated(@date_str).paginate(:page => params[:page])
  end

end
