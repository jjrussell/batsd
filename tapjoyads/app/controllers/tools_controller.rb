class ToolsController < WebsiteController
  layout 'tabbed'
  
  filter_access_to :all
  
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
    render :json => { :success => payout.save }
  end
  
  def new_transfer
  end
  
  def create_transfer
    Partner.transaction do      
      partner = Partner.find(params[:partner_id])
      amount = (params[:transfer_amount].to_f * 100).to_i
      payout = partner.payouts.build(:amount => amount, :month => Time.zone.now.month, :year => Time.zone.now.year, :payment_method => 3)
      payout.save!
      
      order = partner.orders.build(:amount => amount, :status => 1, :payment_method => 3)
      order.save!
      
      if params[:marketing_amount].to_f > 0
        marketing_order = partner.orders.build(:amount => (params[:marketing_amount].to_f * 100).to_i, :status => 1, :payment_method => 2)
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
    sdb = RightAws::SdbInterface.new(nil, nil, {:multi_thread => true, :port => 80, :protocol => 'http'})

    @failed_sdb_saves = {}

    this_hour_key = (Time.zone.now.to_f / 1.hour).to_i
    last_hour_key = ((Time.zone.now.to_f - 1.hour) / 1.hour).to_i

    sdb.list_domains do |result|
      result[:domains].each do |domain_name|
        this_hour_count = Mc.get_count("failed_sdb_saves.#{domain_name}.#{this_hour_key}")
        last_hour_count = Mc.get_count("failed_sdb_saves.#{domain_name}.#{last_hour_key}")
        
        @failed_sdb_saves[domain_name] = [this_hour_count, last_hour_count]
      end
    end
  end

  def disabled_popular_offers
    @offers_count_hash = Mc.get('disabled_popular_offers') do
      {}
    end
=begin
    # test data
    @offers_count_hash = {
      'f7cc285b-1518-4c98-979f-ac877bcf3173' => 42,
      'f8622934-11a8-4796-9517-d73b1a084fb4' => 32,
      'f87a90ad-3b18-4093-8a34-bc11e51d4ea6' => 22,
    }
=end
    @offers = Offer.find(@offers_count_hash.keys, :include => [:partner])
  end
end
