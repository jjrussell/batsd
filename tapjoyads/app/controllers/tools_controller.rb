class ToolsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all

  after_filter :save_activity_logs, :only => [ :update_user, :update_android_app, :update_device, :resolve_clicks, :award_currencies, :update_award_currencies ]

  def index
  end

  def new_transfer
  end

  def monthly_data
    most_recent_period = Date.current.beginning_of_month.prev_month
    @period = params[:period].present? ? Date.parse(params[:period]) : most_recent_period

    @months = []
    date = Date.parse('2009-06-01') #the first month of the platform
    while date <= most_recent_period
      @months << date.strftime('%b %Y')
      date += 1.month
    end

    conditions = [ "month = ? AND year = ? AND partner_id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'", @period.month, @period.year ]
    MonthlyAccounting.using_slave_db do
      expected    = Partner.count(:conditions => [ "created_at < ?", @period.next_month ])
      actual      = MonthlyAccounting.count(:conditions => [ "month = ? AND year = ?", @period.month, @period.year ])
      @completed  = actual * 100.0 / expected

      @spend      = MonthlyAccounting.sum(:spend,             :conditions => conditions) /-100.0
      @marketing  = MonthlyAccounting.sum(:marketing_orders,  :conditions => conditions) / 100.0
      @new_orders = MonthlyAccounting.sum(:website_orders,    :conditions => conditions) / 100.0 +
                    MonthlyAccounting.sum(:invoiced_orders,   :conditions => conditions) / 100.0
      @transfers  = MonthlyAccounting.sum(:transfer_orders,   :conditions => conditions) / 100.0
      @earnings   = MonthlyAccounting.sum(:earnings,          :conditions => conditions) / 100.0
      @payouts    = MonthlyAccounting.sum(:payment_payouts,   :conditions => conditions) /-100.0
    end

    @linkshare_est = @spend.to_f * 0.026
    @ads_est = 0.0
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
    @this_hour_skips  = 0
    @last_hour_skips  = 0
    Currency.find((this_hour_failures.keys + last_hour_failures.keys).uniq, :include => :app).each do |currency|
      hash                    = {}
      hash[:currency]         = currency
      hash[:this_hour_total]  = Mc.get_count("send_currency_failure.#{currency.id}.#{this_hour_mc_time}")
      hash[:last_hour_total]  = Mc.get_count("send_currency_failure.#{currency.id}.#{last_hour_mc_time}")
      hash[:this_hour_unique] = (this_hour_failures[currency.id] || []).length
      hash[:last_hour_unique] = (last_hour_failures[currency.id] || []).length
      hash[:this_hour_skips]  = Mc.get_count("send_currency_skip.#{currency.id}.#{this_hour_mc_time}")
      hash[:last_hour_skips]  = Mc.get_count("send_currency_skip.#{currency.id}.#{last_hour_mc_time}")

      @failures << hash
      @this_hour_total  += hash[:this_hour_total]
      @last_hour_total  += hash[:last_hour_total]
      @this_hour_unique += hash[:this_hour_unique]
      @last_hour_unique += hash[:last_hour_unique]
      @this_hour_skips  += hash[:this_hour_skips]
      @last_hour_skips  += hash[:last_hour_skips]
    end
  end

  def failed_sdb_saves
    this_hour_key         = (Time.zone.now.to_f / 1.hour).to_i
    last_hour_key         = ((Time.zone.now.to_f - 1.hour) / 1.hour).to_i
    @failed_sdb_saves     = {}

    SimpledbResource.get_domain_names.each do |domain_name|
      sdb_this_hour_count = Mc.get_count("failed_sdb_saves.sdb.#{domain_name}.#{this_hour_key}")
      sdb_last_hour_count = Mc.get_count("failed_sdb_saves.sdb.#{domain_name}.#{last_hour_key}")
      mc_this_hour_count  = Mc.get_count("failed_sdb_saves.mc.#{domain_name}.#{this_hour_key}")
      mc_last_hour_count  = Mc.get_count("failed_sdb_saves.mc.#{domain_name}.#{last_hour_key}")

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
    @lb_names      = Rails.env.production? ? %w( masterjob-lb job-lb website-lb dashboard-lb api-lb test-lb util-lb ) : []
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

  def ses_status
    ses = AWS::SimpleEmailService.new
    @quotas = ses.quotas
    @statistics = ses.statistics.sort_by { |s| -s[:sent].to_i }
    @verified_senders = ses.email_addresses.collect
    @queue = Sqs.queue(QueueNames::FAILED_EMAILS)
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
    if params[:udid].blank? && params[:click_key].present?
      click = Click.find(params[:click_key])
      params[:udid] = click.udid if click.present?
    end
    if params[:udid].present?
      udid = params[:udid].downcase
      @device = Device.new(:key => udid)
      if @device.is_new
        flash.now[:error] = "Device with ID #{udid} not found"
        @device = nil
        return
      end
      @cut_off_date = (params[:cut_off_date] || Time.zone.now).to_i
      conditions = [
        "udid = '#{udid}'",
        "clicked_at < '#{@cut_off_date}'",
        "clicked_at > '#{@cut_off_date - 1.month}'",
      ].join(' and ')
      @clicks = []
      @rewarded_clicks_count = 0
      @jailbroken_count = 0
      @not_rewarded_count = 0
      @blocked_count = 0
      @rewarded_failed_clicks_count = 0
      @rewards = {}
      click_app_ids = []
      NUM_CLICK_DOMAINS.times do |i|
        Click.select(:domain_name => "clicks_#{i}", :where => conditions) do |click|
          @clicks << click
          if click.installed_at?
            @rewards[click.reward_key] = Reward.find(click.reward_key)
            if @rewards[click.reward_key] && (@rewards[click.reward_key].send_currency_status == 'OK' || @rewards[click.reward_key].send_currency_status == '200')
              @rewarded_clicks_count += 1
            else
              @rewarded_failed_clicks_count += 1
            end
          end
          @jailbroken_count += 1 if click.type =~ /install_jailbroken/
          if click.block_reason?
            if click.block_reason =~ /TooManyUdidsForPublisherUserId/
              @blocked_count += 1
            else
              @not_rewarded_count += 1
            end
          end
          click_app_ids << [click.publisher_app_id, click.advertiser_app_id, click.displayer_app_id]
        end
      end

      # find all apps at once and store in look up table
      @click_apps = {}
      Offer.find_all_by_id(click_app_ids.flatten.uniq).each do |app|
        @click_apps[app.id] = app
      end

      @apps = Offer.find_all_by_id(@device.parsed_apps.keys).map do |app|
        [ @device.last_run_time(app.id), app ]
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
    device.internal_notes = params[:internal_notes]
    if params[:opt_out_offer_types]
      params[:opt_out_offer_types].each do |offer_type|
        device.opt_out_offer_types = offer_type
      end
    else
      device.opt_out_offer_types = []
    end
    device.opted_out = params[:opted_out] == '1'
    device.banned = params[:banned] == '1'
    device.serial_save
    flash[:notice] = 'Device successfully updated.'
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
      redirect_to device_info_tools_path and return
    end
    log_activity(click)

    if click.currency_id.nil? # old clicks don't have currency_id
      currencies = Currency.find_all_by_app_id(click.publisher_app_id)
      if currencies.length == 1
        click.currency_id = currencies.first.id
      else
        flash[:error] = "Ambiguity -- the publisher app has more than one currency and currency_id was not specified."
        redirect_to device_info_tools_path(:udid => click.udid) and return
      end
    end

    if click.clicked_at < Time.zone.now - 47.hours
      click.clicked_at = Time.zone.now - 1.minute
      flash[:error] = "Because the click was from 48+ hours ago this might fail. If it doesn't go through, try again in a few minutes."
    end

    click.manually_resolved_at = Time.zone.now
    click.serial_save

    if Rails.env.production?
      url = "#{API_URL}/"
      if click.type == 'generic'
        url += "offer_completed?click_key=#{click.key}"
      else
        url += "connect?app_id=#{click.advertiser_app_id}&udid=#{click.udid}"
      end
      Downloader.get_with_retry url
    end

    redirect_to device_info_tools_path(:udid => click.udid)
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
      @app.download_icon(params[:url]) unless params[:url].blank?
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
      @date = Time.zone.parse("#{params[:year]}-#{params[:month]}-01")
    else
      @date = Time.zone.now.beginning_of_month
    end
    @payout_infos = PayoutInfo.recently_updated(@date)
  end

  def manage_user_roles
    if params[:email]
      email = params[:email]
      email += "@tapjoy.com" unless email.match(/@/)
      @user = User.find_by_email(email)
      if @user.nil?
        flash.now[:error] = "User #{params[:email]} not found"
      else
        do_not_add = UserRole.find_all_by_name('admin')
        @unassigned_user_roles = (UserRole.all - @user.user_roles - do_not_add).map{|role|[role.name, role.id]}.sort
      end
    end
  end

  def update_user_roles
    user = User.find_by_id(params[:id])
    user_roles = UserRole.find_all_by_id(params[:user_roles])
    user_roles.each do |user_role|
      user.user_roles << user_role unless user.user_roles.include?(user_role)
    end
    flash[:notice] = "Added #{user_roles.map(&:name).sort.to_json} to #{user.email}"
    redirect_to manage_user_roles_tool_path(:email => user.email)
  end

  def freemium_android
    results = StoreRank.top_freemium_android_apps
    @apps = results['apps']
    @created_at = Time.zone.parse(results['created_at'])
    @tapjoy_apps = {}
    Offer.find_all_by_id(@apps.map{|app|app['tapjoy_apps']}.flatten).each do |app|
      @tapjoy_apps[app.id] = app
    end
  end

  def award_currencies
    @publisher_app = App.find_in_cache(params[:publisher_app_id])
    return unless verify_records([ @publisher_app ])

    support_request = SupportRequest.find_by_udid_and_app_id(params[:udid], params[:publisher_app_id])
    if support_request.nil?
      flash[:error] = "Support request not found. The user must submit a support request for the app in order to award them currency."
      redirect_to :action => :device_info, :udid => params[:udid]
      return
    end
    @publisher_user_id = support_request.publisher_user_id
  end

  def update_award_currencies
    if params[:amount].nil? || params[:amount].empty?
      flash[:error] = "Must provide an amount."
      redirect_to :action => :award_currencies, :publisher_app_id => params[:publisher_app_id], :currency_id => params[:currency_id], :udid =>params[:udid]
      return
    end

    customer_support_reward = Reward.new
    customer_support_reward.type                       =  'customer support'
    customer_support_reward.udid                       =  params[:udid]
    customer_support_reward.publisher_user_id          =  params[:publisher_user_id]
    customer_support_reward.currency_id                =  params[:currency_id]
    customer_support_reward.publisher_app_id           =  params[:publisher_app_id]
    customer_support_reward.advertiser_app_id          =  params[:publisher_app_id]
    customer_support_reward.offer_id                   =  params[:publisher_app_id]
    customer_support_reward.currency_reward            =  params[:amount]
    customer_support_reward.publisher_amount           =  0
    customer_support_reward.advertiser_amount          =  0
    customer_support_reward.tapjoy_amount              =  0
    customer_support_reward.customer_support_username  =  current_user.username

    message = customer_support_reward.serialize
    Sqs.send_message(QueueNames::SEND_CURRENCY, message)

    flash[:notice] = " Successfully awarded #{params[:amount]} currency. "
    redirect_to :action => :device_info, :udid => params[:udid]
  end
end
