class ToolsController < WebsiteController
  layout 'tabbed'
  
  filter_access_to :all
  
  after_filter :save_activity_logs, :only => [ :create_payout, :create_transfer, :create_order ]
  
  def index
  end
  
  def payouts
    @partners = Partner.to_payout
  end
  
  def create_payout
    partner = Partner.find(params[:id])
    cutoff_date = partner.payout_cutoff_date - 1.day
    amount = (params[:amount].to_f * 100).to_i
    payout = partner.payouts.build(:amount => amount, :month => cutoff_date.month, :year => cutoff_date.year)
    log_activity(payout)
    render :json => { :success => payout.save }
  end
  
  def new_transfer
  end
  
  def create_transfer
    sanitized_params = sanitize_currency_params(params, [ :transfer_amount, :marketing_amount ])
    Partner.transaction do
      partner = Partner.find_by_id(params[:partner_id])
      if partner.nil?
        flash[:notice] = "Could not find partner with id: #{params[:partner_id]}"
        redirect_to new_transfer_tools_path and return
      end

      amount = sanitized_params[:transfer_amount].to_i
      payout = partner.payouts.build(:amount => amount, :month => Time.zone.now.month, :year => Time.zone.now.year, :payment_method => 3)
      log_activity(payout)
      payout.save!

      order = partner.orders.build(:amount => amount, :status => 1, :payment_method => 3)
      log_activity(order)
      order.save!

      dollars = amount.to_s
      dollars[-2..-3] = "." if dollars.length > 1
      email = order.partner.users.first.email rescue "(no email)"
      flash[:notice] = "The transfer of <b>$#{dollars}</b> to <b>#{email}</b> was successfully created."

      marketing_amount = sanitized_params[:marketing_amount].to_i
      if marketing_amount > 0
        marketing_order = partner.orders.build(:amount => marketing_amount, :status => 1, :payment_method => 2)
        log_activity(marketing_order)
        marketing_order.save!
      end
      dollars = marketing_amount.to_s
      dollars[-2..-3] = "." if dollars.length > 1
      flash[:notice] += "<br/>The marketing credit of <b>$#{dollars}</b> to <b>#{email}</b> was successfully created."
    end
    redirect_to new_transfer_tools_path
  end
  
  def new_order
    @order = Order.new
  end
  
  def create_order
    order_params = sanitize_currency_params(params[:order], [ :amount ])
    order = Order.new(order_params)
    log_activity(order)
    if order.save
      dollars = order.amount.to_s
      dollars[-2..-3] = "." if dollars.length > 1
      email = order.partner.users.first.email rescue "(no email)"
      flash[:notice] = "The order of <b>$#{dollars}</b> to <b>#{email}</b> was successfully created."
      redirect_to new_order_tools_path
    else
      render :action => :new_order
    end
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
  
  def failed_sdb_saves
    @bad_web_requests = Mc.get('failed_sdb_saves.bad_domains') || {}
    @failed_sdb_saves = {}

    this_hour_key = (Time.zone.now.to_f / 1.hour).to_i
    last_hour_key = ((Time.zone.now.to_f - 1.hour) / 1.hour).to_i

    SimpledbResource.get_domain_names.each do |domain_name|
      this_hour_count = Mc.get_count("failed_sdb_saves.#{domain_name}.#{this_hour_key}")
      last_hour_count = Mc.get_count("failed_sdb_saves.#{domain_name}.#{last_hour_key}")

      @failed_sdb_saves[domain_name] = [this_hour_count, last_hour_count]
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

  def disabled_popular_offers
    @offers_count_hash = Mc.get('tools.disabled_popular_offers') { {} }
    @offers = Offer.find(@offers_count_hash.keys, :include => [:partner, :item])
  end


  def reset_device
    if params[:udid]
      clicks_deleted = 0
      
      device = Device.new(:key => params[:udid])
      device.apps.keys.each do |app_id|
        click = Click.new(:key => "#{params[:udid]}.#{app_id}")
        unless click.new_record?
          click.delete_all 
          clicks_deleted += 1
        end
      end
      
      device.delete_all
      flash[:notice] = "Device successfully reset and #{clicks_deleted} clicks deleted"
    end
  end
end
