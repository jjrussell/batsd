class Dashboard::ToolsController < Dashboard::DashboardController
  layout 'dashboard'
  current_tab :tools

  filter_access_to :all

  before_filter :downcase_device_id, :only => [ :device_info, :update_device, :reset_device ]
  before_filter :set_months, :only => [ :monthly_data, :partner_monthly_balance, :monthly_rev_share_report ]
  before_filter :set_publisher_user, :only => [ :view_pub_user_account, :detach_pub_user_account ]
  after_filter :save_activity_logs, :only => [ :update_user, :update_device, :resolve_clicks, :award_currencies, :update_award_currencies, :detach_pub_user_account ]

  def index
  end

  def fix_rewards
    if params[:reward_key].present?
      reward = Reward.find(params[:reward_key], :consistent => true)
      if reward.present?
        flash.now[:notice] = reward.fix_conditional_check_failed
      else
        flash.now[:error] = 'Reward not found'
      end
    end
  end

  def new_transfer
  end

  def monthly_data
    @period, @period_str = get_period_str(params[:period])
    conditions = ["month = ? AND year = ? AND partner_id not in (?)",
                  @period.month, @period.year, TAPJOY_ACCOUNTING_PARTNER_IDS]
    MonthlyAccounting.using_slave_db do
      expected    = Partner.count(:conditions => [ "created_at < ?", @period.next_month ])
      actual      = MonthlyAccounting.count(:conditions => [ "month = ? AND year = ?", @period.month, @period.year ])
      @completed  = actual * 100.0 / expected

      @spend      = MonthlyAccounting.sum(:spend,             :conditions => conditions) /-100.0
      @marketing  = MonthlyAccounting.sum(:marketing_orders,  :conditions => conditions) / 100.0
      @bonus      = MonthlyAccounting.sum(:bonus_orders,      :conditions => conditions) / 100.0
      @recoupable_marketing = MonthlyAccounting.sum(:recoupable_marketing_orders,      :conditions => conditions) / 100.0
      @new_orders = MonthlyAccounting.sum(:website_orders,    :conditions => conditions) / 100.0 +
                    MonthlyAccounting.sum(:invoiced_orders,   :conditions => conditions) / 100.0
      @transfers  = MonthlyAccounting.sum(:transfer_orders,   :conditions => conditions) / 100.0
      @earnings   = MonthlyAccounting.sum(:earnings,          :conditions => conditions) / 100.0
      @payouts    = MonthlyAccounting.sum(:payment_payouts,   :conditions => conditions) /-100.0
    end

    @linkshare_est = 50_000
    @ads_est = 0.0
    @revenue = @spend + @linkshare_est + @ads_est - @marketing - @bonus - @recoupable_marketing
    @net_revenue = @revenue - @earnings
    @margin = @net_revenue.to_f * 100.0 / @revenue.to_f
  end

  def partner_monthly_balance
    @period_from, @period_from_str = get_period_str(params[:period_from])
    @period_thru, @period_thru_str = get_period_str(params[:period_thru])
    if params[:partner_id].present?
      @partners = Partner.find_all_by_id(params[:partner_id])
    elsif params[:q].present?
      query = params[:q].gsub("'", '')
      @partners = Partner.find_by_name_or_email(query).uniq
    else
      return
    end

    if @partners.empty?
      flash.now[:error] = 'Partner not found'
      return
    end

    @beginning_balances = []
    @ending_balances = []
    @partners.each do |partner|
      from_monthly_accounting = partner.monthly_accounting(@period_from.year, @period_from.month)
      thru_monthly_accounting = partner.monthly_accounting(@period_thru.year, @period_thru.month)
      @beginning_balances << ((from_monthly_accounting.nil?) ? "N/A" : from_monthly_accounting.beginning_balance / 100.0)
      @ending_balances << ((thru_monthly_accounting.nil?) ? "N/A" : thru_monthly_accounting.ending_balance / 100.0)
    end
  end

  def money
    @money_stats = Mc.get('money.cached_stats') || {}
    @last_updated = Time.zone.at(Mc.get('money.last_updated') || 0)
    @total_balance = Mc.get('money.total_balance') || 0
    @total_pending_earnings = Mc.get('money.total_pending_earnings') || 0
    @current_spend_share = SpendShare.current
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
    queues = params[:queue_name].present? ? Sqs.queue("#{QueueNames::BASE_NAME.sub(RUN_MODE_PREFIX, '')}#{params[:queue_name]}").to_a : Sqs.queues
    @queues = queues.map do |queue|
      name = queue.url.split('/').last
      {
        :name          => name,
        :size          => Mc.get("sqs.stats.#{name}.visible_messages") || queue.visible_messages,
        :hidden_size   => Mc.get("sqs.stats.#{name}.invisible_messages") || queue.invisible_messages,
        :visibility    => Mc.get("sqs.stats.#{name}.visibility_timeout") || queue.visibility_timeout,
        :show_run_link => !!(name =~ /^#{RUN_MODE_PREFIX}/)
      }
    end
    @show_run_column = %w(development staging).include?(Rails.env) && @queues.any? { |queue| queue[:show_run_link] }
  end

  def ses_status
    ses = AWS::SimpleEmailService.new
    @quotas = ses.quotas
    @statistics = ses.statistics.sort_by { |s| -s[:sent].to_i }
    @verified_senders = ses.email_addresses.collect
    @queue = Sqs.queue(QueueNames::FAILED_EMAILS)
  end

  def disabled_popular_offers
    @offers_count_hash = Mc.distributed_get('tools.disabled_popular_offers') { {} }
    @offers = Offer.find(@offers_count_hash.keys, :include => [:partner, :item])
  end

  def reset_device
    if params[:device_id]
      device_id = params[:device_id]
      clicks_deleted = 0

      device = Device.find_by_device_id(params[:device_id])
      NUM_CLICK_DOMAINS.times do |i|
        Click.select(:domain_name => "clicksV3_#{i}", :where => "itemName() like '#{device.key}.%'") do |click|
          click.delete_all
          clicks_deleted += 1
        end
      end

      device.delete_all
      flash.now[:notice] = "Device successfully reset and #{clicks_deleted} clicks deleted"
    end
  end

  def device_info
    # these fields are copy-and-pasted into a lot, so let's trim whitespaces
    [:device_id, :click_key, :email_address, :udid, :mac_address, :advertising_id].each do |param|
      params[param].strip! unless params[param].nil?
    end

    now = Time.zone.now

    @start_date = params[:start_date].present? ? Time.parse(params[:start_date]) :  (now - Device::RECENT_CLICKS_RANGE)
    @end_date = params[:end_date].present? ? Time.parse(params[:end_date]) : now

    @start_date = now if @start_date > now
    @end_date = now if @end_date > now

    if params[:device_id].blank? && params[:click_key].present?
      click = Click.find(params[:click_key])
      params[:device_id] = click.tapjoy_device_id if click.present?
    end

    if params[:device_id].present?
      device_id = params[:device_id].downcase.gsub(/:/,"")
      @device = Device.find_by_device_id(device_id)

      if @device.nil? || @device.is_new
        flash.now[:error] = "Device with ID #{device_id} not found"
        @device = nil
        return
      end

      conditions = [
        "udid = '#{@device.udid}' or tapjoy_device_id = '#{@device.key}'",
        "clicked_at > '#{@start_date.to_i}'",
        "clicked_at < '#{@end_date.to_i}'",
      ].join(' and ')
      @clicks = []
      NUM_CLICK_DOMAINS.times do |i|
        Click.select(:domain_name => "clicksV3_#{i}", :where => conditions) do |click|
          @clicks << click unless click.tapjoy_games_invitation_primary_click?
        end
        @clicks = @clicks.sort_by {|click| -click.clicked_at.to_f }
      end

      @rewarded_clicks_count = 0
      @jailbroken_count = 0
      @not_rewarded_count = 0
      @blocked_count = 0
      @rewarded_failed_clicks_count = 0
      @force_converted_count = 0
      @non_rewarded_count = 0
      @rewards = {}
      @support_requests_created = SupportRequest.count(:where => "tapjoy_device_id = '#{@device.key}' or udid = '#{@device.udid}'")
      click_app_ids = nil, []
      @clicks.each do |click|
        next if click.tapjoy_games_invitation_primary_click?
        if click.installed_at?
          @rewards[click.reward_key] = Reward.find(click.reward_key)
          if click.force_convert
            @force_converted_count += 1
          elsif click.currency_reward_zero?
            @non_rewarded_count += 1
          elsif @rewards[click.reward_key] && @rewards[click.reward_key].successful?
            @rewarded_clicks_count += 1
          else
            @rewarded_failed_clicks_count += 1
          end
        end
        @jailbroken_count += 1 if click.type =~ /install_jailbroken/
        if click.block_reason?
          if click.block_reason =~ /TooManyTapjoyDeviceIDsForPublisherUserId|TooManyUdidsForPublisherUserId/
            @blocked_count += 1
          else
            @not_rewarded_count += 1
          end
        end
        click_app_ids.push(click.publisher_app_id, click.advertiser_app_id, click.displayer_app_id)
      end

      # find all apps at once and store in look up table
      @click_apps = {}
      Offer.find_all_by_id(click_app_ids.uniq).each do |app|
        @click_apps[app.id] = app
      end

      @apps = Offer.find_all_by_id(@device.parsed_apps.keys).map do |app|
        [ @device.last_run_time(app.id), app ]
      end.sort_by(&:first).reverse

    elsif params[:email_address].present?
      #TODO(isingh) - Fix this
      @all_device_ids = SupportRequest.find_all_by_email_address(params[:email_address]).map(&:tapjoy_device_id)
      gamer = Gamer.find_by_email(params[:email_address])
      @all_device_ids += gamer.gamer_devices.map(&:device_id) if gamer.present?
      @all_device_ids.uniq!
      if @all_device_ids.empty?
        flash.now[:error] = "No Device IDs associated with the email address: #{params[:email_address]}"
      elsif @all_device_ids.size == 1
        redirect_to :action => :device_info, :device_id => @all_device_ids.first, :email_address => params[:email_address]
      end

    elsif params[:mac_address].present?
      mac_address = params[:mac_address].downcase.gsub(/:/,"")
      device_identifier = DeviceIdentifier.new(:key => mac_address)
      if device_identifier.present?
        redirect_to :action => :device_info, :device_id => device_identifier.device_id, :mac_address => params[:mac_address]
      else
        flash.now[:error] = "No Device IDs associated with the MAC address: #{params[:mac_address]}"
      end

    elsif params[:advertising_id].present?
      device_identifier = DeviceIdentifier.new(:key => params[:advertising_id])
      if device_identifier.present?
        redirect_to :action => :device_info, :device_id => device_identifier.device_id, :advertising_id => params[:advertising_id]
      else
        flash.now[:error] = "No Device IDs associated with the Advertising ID: #{params[:advertising_id]}"
      end

    elsif params[:udid].present?
      device_identifier = Device.find_by_device_id(params[:udid])
      if device_identifier.present?
        redirect_to :action => :device_info, :device_id => (device_identifier.has_tapjoy_id? ? device_identifier.key : device_identifier.udid), :udid => params[:udid]
      else
        flash.now[:error] = "No Device IDs associated with the UDID: #{params[:udid]}"
      end
    end
  end

  def update_device
    device = Device.new :key => params[:device_id]
    log_activity(device)
    device.internal_notes = params[:internal_notes]
    opted_out_types = params[:opt_out_offer_types] || []
    opted_in_types  = device.opt_out_offer_types - opted_out_types
    opted_out_types.each { |type| device.opt_out_offer_types = type }
    opted_in_types.each  { |type| device.delete('opt_out_offer_types', type) }
    device.opted_out = params[:opted_out] == '1'
    current_ban_status = device.banned
    device.banned = params[:banned] == '1'
    if device.banned != current_ban_status
      unless params[:ban_reason].empty?
        device.ban_notes = device.ban_notes << {:date => Time.now.strftime("%m/%d/%y"),
                                                :reason => params[:ban_reason],
                                                :action => device.banned ? 'Banned' : 'Unbanned'}
      else
        flash[:error] = "Ban Reason cannot be blank."
        return redirect_to :back
      end
    end
    device.save
    device.unsuspend! if params[:unsuspend] == '1'
    flash[:notice] = 'Device successfully updated.'
    redirect_to :action => :device_info, :device_id => params[:device_id]
  end

  def recreate_device_identifiers
    device = Device.find_by_device_id(params[:device_id])
    if device.nil?
      flash[:error] = "Unable to find a device with Device ID: #{params[:device_id]}"
    else
      Sqs.send_message(QueueNames::CREATE_DEVICE_IDENTIFIERS, {'device_id' => device.key}.to_json)
      flash[:notice] = "The identifiers for the device #{device.key} should be recreated soon."
    end
    redirect_to :action => :device_info, :device_id => params[:device_id]
  end

  def managed_partner_ids
    Mc.get_and_put('managed_partners', false, 1.minute) do
      User.account_managers.map(&:partners).flatten.uniq.map(&:id)
    end
  end

  def resolve_clicks
    click = Click.new(:key => params[:click_id])
    if click.new_record?
      flash[:error] = 'Unknown click id.'
      redirect_to device_info_tools_path and return
    end

    if params[:publisher_app_id].blank?
      flash[:error] = 'publisher_app_id not passed in'
    elsif params[:publisher_app_id] == click.publisher_app_id
      log_activity(click)
      begin
        click.resolve!
      rescue Exception => e
        flash[:error] = "#{e}"
      end
    else
      matched_pub_ids = click.previous_publisher_ids.reject { |i| i['publisher_app_id'] != params[:publisher_app_id] }
      unless matched_pub_ids.empty?
        most_recent = matched_pub_ids.sort { |a, b| a['updated_at'] <=> b['updated_at'] }.last
        redirect_to award_currencies_tools_path(:publisher_app_id => most_recent['publisher_app_id'],
                                                :udid => click.udid,
                                                :currency_id => (most_recent['currency_id'] || App.find(params[:publisher_app_id]).primary_currency.id),
                                                :click_id => click.id,
                                                :device_id => click.tapjoy_device_id,
                                                :currency_reward => most_recent['currency_reward'])
        return
      end
      flash[:error] = "Publisher ID #{publisher_id} not found for Click #{click.id}"
    end
    redirect_to device_info_tools_path(:device_id => click.tapjoy_device_id)
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

  def award_currencies
    @publisher_app = App.find_in_cache(params[:publisher_app_id])
    return unless verify_records([ @publisher_app ])

    if params[:device_id]
      device = Device.find_by_device_id(params[:device_id])
      @publisher_user_id = device.publisher_user_ids[params[:publisher_app_id]]
    end

    @amount = params[:currency_reward] if params[:currency_reward].present?

    support_request = SupportRequest.find_support_request(params[:udid], params[:device_id], params[:publisher_app_id])
    if support_request.nil?
      click = Click.find(params[:click_id]) if params[:click_id].present?
      click ||= Click.find_by_udid_and_publisher_app_id(params[:udid], params[:publisher_app_id])
      if click.nil?
        flash[:error] = "Support request not found. The user must submit a support request for the app in order to award them currency."
        redirect_to :action => :device_info, :device_id => params[:device_id] and return
      else
        @publisher_user_id ||= click.publisher_user_id
      end
    else
      @publisher_user_id ||= support_request.publisher_user_id
    end
  end

  def update_award_currencies
    if params[:amount].nil? || params[:amount].empty?
      flash[:error] = "Must provide an amount."
      redirect_to :action => :award_currencies, :publisher_app_id => params[:publisher_app_id], :currency_id => params[:currency_id], :udid => params[:udid], :device_id => params[:device_id]
      return
    end
    reward_key = nil
    if params[:click_id].present?
      click = Click.new(:key => params[:click_id])
      reward_key = click.reward_key unless click.new_record?
    end
    customer_support_reward = Reward.new(:key => reward_key)
    customer_support_reward.type                       =  'customer support'
    customer_support_reward.udid                       =  params[:udid]
    customer_support_reward.tapjoy_device_id           =  params[:device_id]
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
    customer_support_reward.click_key                  =  params[:click_id]
    customer_support_reward.save

    Sqs.send_message(QueueNames::SEND_CURRENCY, customer_support_reward.key)

    flash[:notice] = " Successfully awarded #{params[:amount]} currency. "
    redirect_to :action => :device_info, :device_id => params[:device_id]
  end

  def view_pub_user_account
    @publisher_app = App.find(params[:publisher_app_id])
    unless verify_records([ @publisher_app ])
      flash[:error] = "Publisher app not found"
      redirect_to :action => :device_info and return
    end

    @devices = []
    @pub_user.tapjoy_device_ids.each { |device_id| @devices << Device.find_by_device_id(device_id) }
    @devices.sort! do |a,b|
      a_last = a.last_run_time(@publisher_app.id) || Time.at(0)
      b_last = b.last_run_time(@publisher_app.id) || Time.at(0)
      b_last <=> a_last
    end
  end

  def detach_pub_user_account
    if @pub_user.remove!(params[:device_id])
      flash[:notice] = "Successfully detached device from user account."
    else
      flash[:error] = "Failed to detach device."
    end
    redirect_to :action => :view_pub_user_account, :publisher_app_id => params[:publisher_app_id], :publisher_user_id => params[:publisher_user_id]
  end

  def view_conversion_attempt
    @attempt = ConversionAttempt.new(:key => params[:conversion_attempt_key])
    if @attempt.is_new
      flash[:error] = "Conversion attempt not found"
      redirect_to :action => :device_info and return
    end
  end

  def force_conversion
    click = Click.new(:key => params[:click_key])
    if click.is_new
      flash[:error] = "Click not found"
      redirect_to :action => :device_info and return
    else
      attempt = ConversionAttempt.new(:key => click.reward_key)
      if attempt.resolution == 'force_converted'
        flash[:error] = "Conversion has already been forced"
        redirect_to :action => :device_info, :click_key => click.key and return
      end

      if !click.block_reason?
        flash[:error] = "Only blocked conversions can be force converted"
        redirect_to :action => :device_info, :click_key => click.key and return
      end
    end

    click.force_convert = true
    click.force_converted_by = current_user.username
    click.save

    message = { :click_key => click.key, :install_timestamp => Time.zone.now.to_f.to_s }.to_json
    Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)

    flash[:message] = "Force conversion request sent. It may take some time for this request to be processed."
    redirect_to :action => :device_info, :click_key => click.key
  end

  def monthly_rev_share_report
  end

  def download_monthly_rev_share_report
    start_time = Time.zone.parse(params[:start_time]).beginning_of_month
    year  = start_time.year
    month = start_time.month
    start_time = start_time.to_f

    partner_conditions = [
      %Q(after_state     like '%"rev_share":%'),
      %Q(after_state not like '%"rev_share":null%'),
      %Q(after_state not like '%"rev_share":""%'),
    ].join(' and ')

    currency_conditions = [
      %Q(after_state     like '%"rev_share_override":%'),
      %Q(after_state not like '%"rev_share_override":null%'),
      %Q(after_state not like '%"rev_share_override":""%'),
    ].join(' and ')

    where_clause = [
      %Q(`updated-at` is not null),
      %Q(`updated-at` >= '#{start_time}'),
      %Q(`updated-at` <  '#{start_time + 1.month}'),
      "((#{partner_conditions}) or (#{currency_conditions}))",
    ].join(' and ')

    data = ['time,partner_id,partner_name,app_id,app_name,user,old_rev_share,new_rev_share,notes']
    next_token = nil

    begin
      response = ActivityLog.select(:where => where_clause, :order_by => '`updated-at` desc', :next_token => next_token)
      next_token = response[:next_token]
      response[:items].each do |item|
        row = parse_row(item)
        data << row.map{|attr| sanitize_for_csv(attr) }.join(",") unless row.nil?
      end
    end until next_token.nil?

    send_data(data.join("\n"), :type => 'text/csv', :filename => "monthly_rev_share_#{year}_#{month}.csv")
  end

  # This tool has moved to tapjoy.com. Leaving this here for auth rules.
  def gamers
    redirect_to "#{WEBSITE_URL}/admin"
  end

  private

  def parse_row(activity_log)
    case activity_log.object_type
    when 'Currency'
      app = Currency.find(activity_log.object_id).app
      partner = app.partner
      attribute = 'rev_share_override'
    when 'Partner'
      app = nil
      partner = Partner.find(activity_log.object_id)
      attribute = 'rev_share'
    else
      raise "Unexpected item type #{activity_log.object_type}"
    end

    before_value = activity_log.before_state[attribute]
    after_value  = activity_log.after_state[attribute]

    return nil if before_value.blank? && after_value.blank?

    row = [
      activity_log.updated_at,
      partner.id,
      partner.name,
      app.try(:id),
      app.try(:name),
      activity_log.user,
      before_value,
      after_value,
      activity_log.after_state['account_manager_notes'],
    ]
  end

  def sanitize_for_csv(str)
    str.to_s.gsub(/\n|\r/, ';').gsub(",", ' ')
  end

  def downcase_device_id
    downcase_param(:device_id)
  end

  def get_period_str(period)
    period = period.present? ? Date.parse(period) : Date.current.beginning_of_month.prev_month
    period_str = period.strftime("%b %Y")
    return period, period_str
  end

  def set_months
    most_recent_period = Date.current.beginning_of_month.prev_month
    @months = []
    date = Date.parse('2009-06-01') #the first month of the platform
    while date <= most_recent_period
      @months << date.strftime('%b %Y')
      date += 1.months
    end
    true
  end

  def set_publisher_user
    @pub_user = PublisherUser.new(:key => "#{params[:publisher_app_id]}.#{params[:publisher_user_id]}")
    if params[:publisher_app_id].blank? || @pub_user.is_new
      flash[:error] = "Invalid publisher user account parameters."
      redirect_to :action => :device_info
    end
  end
end
