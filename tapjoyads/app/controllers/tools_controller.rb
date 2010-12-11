class ToolsController < WebsiteController
  layout 'tabbed'
  
  filter_access_to :all
  
  after_filter :save_activity_logs, :only => [ :create_payout, :create_transfer, :create_order, :update_user, :create_generic_offer ]
  
  def index
  end
  
  def payouts
    @partners = Partner.to_payout
  end
  
  def create_payout
    partner = Partner.find(params[:id])
    cutoff_date = partner.payout_cutoff_date - 1.day
    amount = (params[:amount].to_f * 100).round
    payout = partner.payouts.build(:amount => amount, :month => cutoff_date.month, :year => cutoff_date.year)
    log_activity(payout)
    render :json => { :success => payout.save }
  end
  
  def new_transfer
  end
  
  def new_order
    @order = Order.new
  end
  
  def create_order
    order_params = sanitize_currency_params(params[:order], [ :amount ])
    @order = Order.new(order_params)
    log_activity(@order)
    if @order.save
      dollars = @order.amount.to_s
      dollars[-2..-3] = "." if dollars.length > 1
      email = @order.partner.users.first.email rescue "(no email)"
      flash[:notice] = "The order of <b>$#{dollars}</b> to <b>#{email}</b> was successfully created."
      redirect_to new_order_tools_path
    else
      render :action => :new_order
    end
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

    conditions = "month = #{month} and year = #{year} and id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'"
    MonthlyAccounting.using_slave_db do
      @spend      = MonthlyAccounting.sum(:spend,             :conditions => conditions) /-100.0
      @marketing  = MonthlyAccounting.sum(:marketing_orders,  :conditions => conditions) / 100.0
      @new_orders = MonthlyAccounting.sum(:website_orders,    :conditions => conditions) / 100.0 +
                    MonthlyAccounting.sum(:invoiced_orders,   :conditions => conditions) / 100.0
      @transfers  = MonthlyAccounting.sum(:transfer_orders,   :conditions => conditions) / 100.0
      @earnings   = MonthlyAccounting.sum(:earnings,          :conditions => conditions) / 100.0
      @payouts    = MonthlyAccounting.sum(:payment_payouts,   :conditions => conditions) /-100.0
    end

    @linkshare_est = @spend.to_f * 0.035
    @ads_est = 400.0 * 30
    @revenue = @spend + @linkshare_est + @ads_est - @marketing
    @net_revenue = @revenue - @earnings
    @margin = @net_revenue.to_f * 100.0 / @revenue.to_f
  end

  def money
    @money_stats = Mc.get('money.cached_stats') || {}
    @daily_money_stats = Mc.get('money.daily_cached_stats') || {}
    @combined_money_stats = @money_stats.merge(@daily_money_stats)
    @last_updated = Time.zone.at(Mc.get('money.last_updated') || 0)
    @daily_last_updated = Time.zone.at(Mc.get('money.daily_last_updated') || 0)
    @total_balance = Mc.get('money.total_balance') || 0
    @total_pending_earnings = Mc.get('money.total_pending_earnings') || 0
  end
  
  def failed_downloads
    this_hour_counts = Mc.get("failed_downloads.#{(Time.zone.now.to_f / 1.hour).to_i}") { {} }
    last_hour_counts = Mc.get("failed_downloads.#{((Time.zone.now.to_f - 1.hour) / 1.hour).to_i}") { {} }
    @this_hour_total = this_hour_counts.values.sum
    @last_hour_total = last_hour_counts.values.sum
    @combined_counts = {}
    (this_hour_counts.keys + last_hour_counts.keys).uniq.each do |url|
      app_ids = Currency.find(:all, :conditions => "callback_url LIKE '#{url}%'").map(&:app_id)
      offers = Offer.find(app_ids)
      @combined_counts[url] = [ (this_hour_counts[url] || 0), (last_hour_counts[url] || 0), offers ]
    end
  end
  
  def failed_sdb_saves
    @bad_web_requests = Mc.get('failed_sdb_saves.bad_domains') || {}
    @failed_sdb_saves = {}

    this_hour_key = (Time.zone.now.to_f / 1.hour).to_i
    last_hour_key = ((Time.zone.now.to_f - 1.hour) / 1.hour).to_i

    SimpledbResource.get_domain_names.each do |domain_name|
      sdb_this_hour_count = Mc.get_count("failed_sdb_saves.sdb.#{domain_name}.#{this_hour_key}")
      sdb_last_hour_count = Mc.get_count("failed_sdb_saves.sdb.#{domain_name}.#{last_hour_key}")
      mc_this_hour_count  = Mc.get_count("failed_sdb_saves.mc.#{domain_name}.#{this_hour_key}")
      mc_last_hour_count  = Mc.get_count("failed_sdb_saves.mc.#{domain_name}.#{last_hour_key}")

      @failed_sdb_saves[domain_name] = { :sdb_this_hour => sdb_this_hour_count,
                                         :sdb_last_hour => sdb_last_hour_count,
                                         :mc_this_hour => mc_this_hour_count,
                                         :mc_last_hour => mc_last_hour_count }
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
      flash[:notice] = "Device successfully reset and #{clicks_deleted} clicks deleted"
    end
  end

  def managed_partner_ids
    Mc.get_and_put('managed_partners', false, 1.minute) do
      User.account_managers.map(&:partners).flatten.uniq.map(&:id)
    end
  end

  def resolve_clicks
    click = Click.new(:key => params[:click_id])

    if click.clicked_at < Time.zone.now - 47.hours
      click.clicked_at = Time.zone.now - 1.minute
      flash[:error] = "Because the click was from 48+ hours ago this might fail. If it doens't go through, try again in a few minutes."
    end

    if click.currency_id.nil? # old clicks don't have currency_id
      currencies = Currency.find_all_by_app_id(click.publisher_app_id)
      if currencies.length == 1
        click.currency_id = currencies.first.id
      else
        flash[:error] = "Ambiguity -- the publisher app has more than one currency and currency_id was not specified."
      end
    end

    click.save

    if Rails.env == 'production'
      Downloader.get_with_retry "http://ws.tapjoyads.com/connect?app_id=#{click.advertiser_app_id}&udid=#{click.udid}"
    end

    redirect_to :back
  end

  def unresolved_clicks
    @udid = params[:udid]
    @num_hours = params[:num_hours].nil? ? 48 : params[:num_hours].to_i
    @clicks = []
    cut_off = (Time.zone.now - @num_hours.hours).to_f
    device = Device.new(:key => @udid)

    if @udid
      NUM_CLICK_DOMAINS.times do |i|
        Click.select(:domain_name => "clicks_#{i}", :where => "itemName() like '#{@udid}.%'") do |click|
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

  def new_generic_offer
    @generic_offer = GenericOffer.new
  end

  def create_generic_offer
    generic_offer_params = sanitize_currency_params(params[:generic_offer], [ :price ])
    @generic_offer = GenericOffer.new(generic_offer_params)
    log_activity(@generic_offer)
    if @generic_offer.save
      unless params[:icon].blank?
        b = S3.bucket(BucketNames::TAPJOY)
        b.put("icons/#{@generic_offer.id}.png", params[:icon], {}, "public-read")
      end
      flash[:notice] = 'Successfully created Generic Offer'
      redirect_to statz_path(@generic_offer.primary_offer)
    else
      render :action => :new_generic_offer
    end
  end

end
