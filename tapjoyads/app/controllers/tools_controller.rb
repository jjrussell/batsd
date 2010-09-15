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
    Partner.transaction do      
      partner = Partner.find(params[:partner_id])
      amount = (params[:transfer_amount].to_f * 100).to_i
      payout = partner.payouts.build(:amount => amount, :month => Time.zone.now.month, :year => Time.zone.now.year, :payment_method => 3)
      log_activity(payout)
      payout.save!
      
      order = partner.orders.build(:amount => amount, :status => 1, :payment_method => 3)
      log_activity(order)
      order.save!
      
      if params[:marketing_amount].to_f > 0
        marketing_order = partner.orders.build(:amount => (params[:marketing_amount].to_f * 100).to_i, :status => 1, :payment_method => 2)
        log_activity(marketing_order)
        marketing_order.save!
      end
    end
    
    flash[:notice] = 'The transfer was successfully created.'
    
    redirect_to new_transfer_tools_path
  end
  
  def new_order
  end
  
  def create_order
    order = Order.new(params[:order])
    order.amount = (params[:order][:amount].to_f * 100).to_i
    log_activity(order)
    if order.save
      flash[:notice] = 'The order was successfully created.'
    else
      flash[:error] = 'The order could not be created.'
    end
    redirect_to new_order_tools_path
  end
  
  def money
    @money_stats = Mc.get('money.cached_stats') || (render(:text => "Not Available") and return)
    @time_ranges = @money_stats.keys
    
    @stat_types = @money_stats[@time_ranges.first].keys
    
    @last_updated = Mc.get('money.last_updated') || Time.zone.at(0)
    
    @total_balance = Mc.get('money.total_balance') || 'Not Available'
    @total_pending_earnings = Mc.get('money.total_pending_earnings') || 'Not Available'
  end
  
  def failed_sdb_saves
    @bad_web_requests = Mc.get('failed_sdb_saves.bad_domains')
    @failed_sdb_saves = {}

    this_hour_key = (Time.zone.now.to_f / 1.hour).to_i
    last_hour_key = ((Time.zone.now.to_f - 1.hour) / 1.hour).to_i

    SimpledbResource.sdb.list_domains do |result|
      result[:domains].each do |domain_name|
        this_hour_count = Mc.get_count("failed_sdb_saves.#{domain_name}.#{this_hour_key}")
        last_hour_count = Mc.get_count("failed_sdb_saves.#{domain_name}.#{last_hour_key}")
        
        @failed_sdb_saves[domain_name] = [this_hour_count, last_hour_count]
      end
    end
  end

  def disabled_popular_offers
    @offers_count_hash = Mc.get('tools.disabled_popular_offers') { {} }
    @offers = Offer.find(@offers_count_hash.keys, :include => [:partner, :item])
  end
  
  def beta_websiters
    beta_role = UserRole.find_by_name('beta_website')
    @users = []
    RoleAssignment.find(:all, :conditions => ['user_role_id = ?', beta_role.id] ).each do |role|
      @users << role.user
    end
    
    @users.sort! do |u1, u2|
      u1.partners.first.id <=> u2.partners.first.id
    end
  end
    
    
end
