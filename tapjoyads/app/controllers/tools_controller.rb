class ToolsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all

  before_filter :downcase_udid, :only => [ :device_info, :update_device, :reset_device ]
  after_filter :save_activity_logs, :only => [ :update_user, :update_device, :resolve_clicks, :award_currencies, :update_award_currencies ]

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
    most_recent_period = Date.current.beginning_of_month.prev_month
    @period = params[:period].present? ? Date.parse(params[:period]) : most_recent_period

    @months = []
    date = Date.parse('2009-06-01') #the first month of the platform
    while date <= most_recent_period
      @months << date.strftime('%b %Y')
      date += 1.month
    end

    conditions = [ "month = ? AND year = ? AND partner_id != '#{TAPJOY_PARTNER_ID}'", @period.month, @period.year ]
    MonthlyAccounting.using_slave_db do
      expected    = Partner.count(:conditions => [ "created_at < ?", @period.next_month ])
      actual      = MonthlyAccounting.count(:conditions => [ "month = ? AND year = ?", @period.month, @period.year ])
      @completed  = actual * 100.0 / expected

      @spend      = MonthlyAccounting.sum(:spend,             :conditions => conditions) /-100.0
      @marketing  = MonthlyAccounting.sum(:marketing_orders,  :conditions => conditions) / 100.0
      @bonus      = MonthlyAccounting.sum(:bonus_orders,      :conditions => conditions) / 100.0
      @new_orders = MonthlyAccounting.sum(:website_orders,    :conditions => conditions) / 100.0 +
                    MonthlyAccounting.sum(:invoiced_orders,   :conditions => conditions) / 100.0
      @transfers  = MonthlyAccounting.sum(:transfer_orders,   :conditions => conditions) / 100.0
      @earnings   = MonthlyAccounting.sum(:earnings,          :conditions => conditions) / 100.0
      @payouts    = MonthlyAccounting.sum(:payment_payouts,   :conditions => conditions) /-100.0
    end

    @linkshare_est = 50_000
    @ads_est = 0.0
    @revenue = @spend + @linkshare_est + @ads_est - @marketing - @bonus
    @net_revenue = @revenue - @earnings
    @margin = @net_revenue.to_f * 100.0 / @revenue.to_f
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
        :size          => queue.visible_messages,
        :hidden_size   => queue.invisible_messages,
        :visibility    => queue.visibility_timeout,
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
    if params[:udid]
      udid = params[:udid]
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
      udid = params[:udid]
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
      @support_requests_created = SupportRequest.count(:where => "udid = '#{udid}'")
      click_app_ids = []
      NUM_CLICK_DOMAINS.times do |i|
        Click.select(:domain_name => "clicks_#{i}", :where => conditions) do |click|
          @clicks << click unless click.tapjoy_games_invitation_primary_click?
          if click.installed_at?
            @rewards[click.reward_key] = Reward.find(click.reward_key)
            if @rewards[click.reward_key] && @rewards[click.reward_key].successful?
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
          click_app_ids.push(click.publisher_app_id, click.advertiser_app_id, click.displayer_app_id)
        end
      end

      # find all apps at once and store in look up table
      @click_apps = {}
      Offer.find_all_by_id(click_app_ids.uniq).each do |app|
        @click_apps[app.id] = app
      end

      @apps = Offer.find_all_by_id(@device.parsed_apps.keys).map do |app|
        [ @device.last_run_time(app.id), app ]
      end.sort_by(&:first).reverse
      @clicks = @clicks.sort_by do |click|
        -click.clicked_at.to_f
      end

    elsif params[:email_address].present?
      @all_udids = SupportRequest.find_all_by_email_address(params[:email_address]).map(&:udid)
      gamer = Gamer.find_by_email(params[:email_address])
      @all_udids += gamer.gamer_devices.map(&:device_id) if gamer.present?
      @all_udids.uniq!
      if @all_udids.empty?
        flash.now[:error] = "No UDIDs associated with the email address: #{params[:email_address]}"
      elsif @all_udids.size == 1
        redirect_to :action => :device_info, :udid => @all_udids.first, :email_address => params[:email_address]
      end

    elsif params[:mac_address].present?
      mac_address = params[:mac_address].downcase.gsub(/:/,"")
      device_identifier = DeviceIdentifier.new(:key => mac_address)
      if device_identifier.udid?
        redirect_to :action => :device_info, :udid => device_identifier.udid, :mac_address => params[:mac_address]
      else
        flash.now[:error] = "No UDIDs associated with the MAC address: #{params[:mac_address]}"
      end
    end
  end

  def update_device
    device = Device.new :key => params[:udid]
    log_activity(device)
    device.internal_notes = params[:internal_notes]
    opted_out_types = params[:opt_out_offer_types] || []
    opted_in_types  = device.opt_out_offer_types - opted_out_types
    opted_out_types.each { |type| device.opt_out_offer_types = type }
    opted_in_types.each  { |type| device.delete('opt_out_offer_types', type) }
    device.opted_out = params[:opted_out] == '1'
    device.banned = params[:banned] == '1'
    device.save
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
      flash[:error] = 'Unknown click id.'
      redirect_to device_info_tools_path and return
    end

    log_activity(click)
    begin
      click.resolve!
    rescue Exception => e
      flash[:error] = "#{e}"
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

    support_request = SupportRequest.find_by_udid_and_app_id(params[:udid], params[:publisher_app_id])
    if support_request.nil?
      click = Click.find_by_udid_and_publisher_app_id(params[:udid], params[:publisher_app_id])
      if click.nil?
        flash[:error] = "Support request not found. The user must submit a support request for the app in order to award them currency."
        redirect_to :action => :device_info, :udid => params[:udid] and return
      else
        @publisher_user_id = click.publisher_user_id
      end
    else
      @publisher_user_id = support_request.publisher_user_id
    end
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
    customer_support_reward.save

    Sqs.send_message(QueueNames::SEND_CURRENCY, customer_support_reward.key)

    flash[:notice] = " Successfully awarded #{params[:amount]} currency. "
    redirect_to :action => :device_info, :udid => params[:udid]
  end

  def downcase_udid
    params[:udid] = params[:udid].downcase if params[:udid].present?
  end

end
